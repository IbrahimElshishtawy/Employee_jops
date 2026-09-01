import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { RealTimeService } from "./realtime.service";
import { CreateConversationDto, SendMessageDto, QueryMessagesDto } from "./dto";
import { NotificationType, AuditAction, Role, Prisma } from "@prisma/client";

@Injectable()
export class MessagesService {
  private readonly logger = new Logger(MessagesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly realtimeService: RealTimeService,
  ) {}

  // ============================================================
  // 1. CONVERSATIONS
  // ============================================================

  async createConversation(senderUserId: string, dto: CreateConversationDto) {
    if (!dto.content || dto.content.trim().length === 0) {
      throw new BadRequestException("Initial message content cannot be empty");
    }

    const senderUser = await this.prisma.user.findUnique({
      where: { id: senderUserId },
      include: { employeeProfile: true },
    });

    if (!senderUser) {
      throw new NotFoundException("Sender user not found");
    }

    // Determine target recipient (HR representative or specific participant)
    let recipientUserId = dto.participantUserId;

    if (!recipientUserId) {
      // Find an active HR Admin if employee starting generic HR inquiry
      const hrUser = await this.prisma.user.findFirst({
        where: {
          role: { in: [Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPER_ADMIN] },
        },
      });
      if (!hrUser) {
        throw new BadRequestException(
          "No HR representative is currently available",
        );
      }
      recipientUserId = hrUser.id;
    }

    if (recipientUserId === senderUserId) {
      throw new BadRequestException(
        "Cannot start a conversation with yourself",
      );
    }

    const recipientUser = await this.prisma.user.findUnique({
      where: { id: recipientUserId },
      include: { employeeProfile: true },
    });

    if (!recipientUser) {
      throw new NotFoundException("Recipient user not found");
    }

    // Check for existing 1-on-1 direct conversation
    const existing = await this.prisma.conversation.findFirst({
      where: {
        isGroup: false,
        AND: [
          { participants: { some: { userId: senderUserId } } },
          { participants: { some: { userId: recipientUserId } } },
        ],
      },
    });

    if (existing) {
      // Send message to existing conversation
      return this.sendMessage(existing.id, senderUserId, {
        content: dto.content,
        attachmentUrl: dto.attachmentUrl,
        idempotencyKey: dto.idempotencyKey,
      });
    }

    // Create new Conversation
    const conversation = await this.prisma.$transaction(async (tx) => {
      const conv = await tx.conversation.create({
        data: {
          title:
            dto.title ||
            `Inquiry: ${senderUser.employeeProfile?.firstName || senderUser.email}`,
          isGroup: false,
          createdByUserId: senderUserId,
          lastMessageAt: new Date(),
        },
      });

      // Add participants
      await tx.conversationParticipant.createMany({
        data: [
          {
            conversationId: conv.id,
            userId: senderUserId,
            role: senderUser.role,
            lastReadAt: new Date(),
          },
          {
            conversationId: conv.id,
            userId: recipientUserId!,
            role: recipientUser.role,
          },
        ],
      });

      // Create initial message
      const message = await tx.chatMessage.create({
        data: {
          conversationId: conv.id,
          senderId: senderUserId,
          content: dto.content.trim(),
          attachmentUrl: dto.attachmentUrl,
          isRead: false,
        },
      });

      return { conv, message };
    });

    // Real-time and Notification delivery (post-commit)
    this.realtimeService.emitToConversation(
      conversation.conv.id,
      "new_message",
      conversation.message,
    );
    this.realtimeService.emitToUsers(
      [recipientUserId],
      "new_conversation",
      conversation.conv,
    );

    try {
      const senderName = senderUser.employeeProfile
        ? `${senderUser.employeeProfile.firstName} ${senderUser.employeeProfile.lastName}`
        : senderUser.email;

      await this.notificationsService.sendNotification(
        recipientUserId,
        `New message from ${senderName}`,
        dto.content.length > 100
          ? `${dto.content.slice(0, 97)}...`
          : dto.content,
        NotificationType.CHAT_MESSAGE,
        {
          conversationId: conversation.conv.id,
          messageId: conversation.message.id,
        },
      );
    } catch (notifErr: any) {
      this.logger.warn(
        `Failed to dispatch message notification: ${notifErr?.message || notifErr}`,
      );
    }

    return conversation.message;
  }

  async getUserConversations(userId: string) {
    const conversations = await this.prisma.conversation.findMany({
      where: {
        participants: { some: { userId } },
      },
      include: {
        participants: {
          include: {
            user: {
              select: {
                id: true,
                email: true,
                role: true,
                employeeProfile: {
                  select: {
                    id: true,
                    firstName: true,
                    lastName: true,
                    avatarUrl: true,
                    jobTitle: true,
                    department: true,
                  },
                },
              },
            },
          },
        },
        messages: {
          where: { isDeleted: false },
          take: 1,
          orderBy: { createdAt: "desc" },
        },
      },
      orderBy: { lastMessageAt: "desc" },
    });

    // Calculate unread count for each conversation
    const result = await Promise.all(
      conversations.map(async (conv) => {
        const unreadCount = await this.prisma.chatMessage.count({
          where: {
            conversationId: conv.id,
            senderId: { not: userId },
            isRead: false,
            isDeleted: false,
          },
        });

        const otherParticipants = conv.participants
          .filter((p) => p.userId !== userId)
          .map((p) => p.user);

        return {
          id: conv.id,
          title: conv.title,
          isGroup: conv.isGroup,
          lastMessage: conv.messages[0] || null,
          unreadCount,
          otherParticipants,
          updatedAt: conv.updatedAt,
        };
      }),
    );

    return result;
  }

  // ============================================================
  // 2. MESSAGES
  // ============================================================

  async getConversationMessages(
    conversationId: string,
    currentUserId: string,
    query: Partial<QueryMessagesDto> = {},
  ) {
    // 1. Participant check (IDOR Protection)
    const isParticipant = await this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: {
          conversationId,
          userId: currentUserId,
        },
      },
    });

    if (!isParticipant) {
      throw new ForbiddenException(
        "You are not an authorized participant in this conversation",
      );
    }

    const { page = 1, limit = 50, before } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.ChatMessageWhereInput = {
      conversationId,
      isDeleted: false,
    };
    if (before) {
      where.createdAt = { lt: new Date(before) };
    }

    const [total, messages] = await Promise.all([
      this.prisma.chatMessage.count({ where }),
      this.prisma.chatMessage.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "asc" },
        include: {
          sender: {
            select: {
              id: true,
              email: true,
              role: true,
              employeeProfile: {
                select: { firstName: true, lastName: true, avatarUrl: true },
              },
            },
          },
        },
      }),
    ]);

    return {
      data: messages,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async sendMessage(
    conversationId: string,
    senderUserId: string,
    dto: SendMessageDto,
  ) {
    if (!dto.content || dto.content.trim().length === 0) {
      throw new BadRequestException(
        "Message content cannot be empty or only whitespace",
      );
    }

    // 1. Verify membership
    const participant = await this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: {
          conversationId,
          userId: senderUserId,
        },
      },
      include: { conversation: { include: { participants: true } } },
    });

    if (!participant) {
      throw new ForbiddenException(
        "You are not a participant in this conversation",
      );
    }

    const senderUser = await this.prisma.user.findUnique({
      where: { id: senderUserId },
      include: { employeeProfile: true },
    });

    // 2. Persist Message & Update Conversation
    const message = await this.prisma.$transaction(async (tx) => {
      const msg = await tx.chatMessage.create({
        data: {
          conversationId,
          senderId: senderUserId,
          content: dto.content.trim(),
          attachmentUrl: dto.attachmentUrl,
          isRead: false,
        },
        include: {
          sender: {
            select: {
              id: true,
              email: true,
              role: true,
              employeeProfile: {
                select: { firstName: true, lastName: true, avatarUrl: true },
              },
            },
          },
        },
      });

      await tx.conversation.update({
        where: { id: conversationId },
        data: { lastMessageAt: new Date() },
      });

      await tx.auditLog.create({
        data: {
          userId: senderUserId,
          action: AuditAction.MESSAGE_SENT,
          entity: "ChatMessage",
          entityId: msg.id,
          payload: { conversationId },
        },
      });

      return msg;
    });

    // 3. Real-Time Event Broadcast
    this.realtimeService.emitToConversation(
      conversationId,
      "new_message",
      message,
    );

    // 4. Notifications to Other Participants
    const otherParticipants = participant.conversation.participants.filter(
      (p) => p.userId !== senderUserId,
    );

    const senderName = senderUser?.employeeProfile
      ? `${senderUser.employeeProfile.firstName} ${senderUser.employeeProfile.lastName}`
      : senderUser?.email || "A user";

    for (const p of otherParticipants) {
      this.notificationsService
        .sendNotification(
          p.userId,
          `New message from ${senderName}`,
          dto.content.length > 100
            ? `${dto.content.slice(0, 97)}...`
            : dto.content,
          NotificationType.CHAT_MESSAGE,
          { conversationId, messageId: message.id },
        )
        .catch((err) => {
          this.logger.warn(
            `Failed to notify participant ${p.userId}: ${err?.message || err}`,
          );
        });
    }

    return message;
  }

  // ============================================================
  // 3. READ STATE & UNREAD COUNTS
  // ============================================================

  async markConversationAsRead(conversationId: string, currentUserId: string) {
    const isParticipant = await this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: {
          conversationId,
          userId: currentUserId,
        },
      },
    });

    if (!isParticipant) {
      throw new ForbiddenException(
        "You are not a participant in this conversation",
      );
    }

    const now = new Date();

    const [updateResult] = await Promise.all([
      this.prisma.chatMessage.updateMany({
        where: {
          conversationId,
          senderId: { not: currentUserId },
          isRead: false,
        },
        data: {
          isRead: true,
          readAt: now,
        },
      }),
      this.prisma.conversationParticipant.update({
        where: {
          conversationId_userId: {
            conversationId,
            userId: currentUserId,
          },
        },
        data: { lastReadAt: now },
      }),
    ]);

    this.realtimeService.emitToConversation(conversationId, "messages_read", {
      conversationId,
      readByUserId: currentUserId,
      readAt: now,
    });

    return {
      message: "Conversation marked as read",
      markedCount: updateResult.count,
    };
  }

  async getUnreadMessageCount(userId: string) {
    const count = await this.prisma.chatMessage.count({
      where: {
        conversation: {
          participants: { some: { userId } },
        },
        senderId: { not: userId },
        isRead: false,
        isDeleted: false,
      },
    });

    return { unreadCount: count };
  }

  async deleteMessage(messageId: string, currentUserId: string) {
    const message = await this.prisma.chatMessage.findUnique({
      where: { id: messageId },
    });

    if (!message) {
      throw new NotFoundException("Message not found");
    }

    const user = await this.prisma.user.findUnique({
      where: { id: currentUserId },
    });

    const isSender = message.senderId === currentUserId;
    const isHr = ([Role.SUPER_ADMIN, Role.HR_ADMIN] as Role[]).includes(
      user?.role as Role,
    );

    if (!isSender && !isHr) {
      throw new ForbiddenException(
        "You do not have permission to delete this message",
      );
    }

    await this.prisma.chatMessage.update({
      where: { id: messageId },
      data: {
        isDeleted: true,
        deletedAt: new Date(),
        deletedById: currentUserId,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: currentUserId,
        action: AuditAction.MESSAGE_DELETED,
        entity: "ChatMessage",
        entityId: messageId,
      },
    });

    this.realtimeService.emitToConversation(
      message.conversationId,
      "message_deleted",
      {
        messageId,
        conversationId: message.conversationId,
      },
    );

    return { message: "Message deleted successfully" };
  }
}
