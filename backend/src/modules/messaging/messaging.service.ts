import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { MessagingRepository } from "./messaging.repository";
import { NotificationsService } from "../notifications/notifications.service";
import { RealTimeService } from "../realtime/realtime.service";
import {
  CreateConversationDto,
  CreateGroupConversationDto,
  SendMessageDto,
  QueryMessagesDto,
} from "./dto";
import { NotificationType, AuditAction, Role } from "@prisma/client";

@Injectable()
export class MessagingService {
  private readonly logger = new Logger(MessagingService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly messagingRepo: MessagingRepository,
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
    const existing = await this.messagingRepo.findDirectConversation(
      senderUserId,
      recipientUserId,
    );

    if (existing) {
      // Send message to existing conversation
      return this.sendMessage(existing.id, senderUserId, {
        content: dto.content,
        attachmentUrl: dto.attachmentUrl,
        idempotencyKey: dto.idempotencyKey,
      });
    }

    // Create new Conversation with initial message
    const { conversation, message } =
      await this.messagingRepo.createConversationWithInitialMessage({
        title:
          dto.title ||
          `Inquiry: ${senderUser.employeeProfile?.firstName || senderUser.email}`,
        isGroup: false,
        createdByUserId: senderUserId,
        participants: [
          { userId: senderUserId, role: senderUser.role },
          { userId: recipientUserId, role: recipientUser.role },
        ],
        initialContent: dto.content,
        attachmentUrl: dto.attachmentUrl,
      });

    // Real-time and Notification delivery
    this.realtimeService.emitToConversation(
      conversation.id,
      "new_message",
      message,
    );
    this.realtimeService.emitToUsers(
      [recipientUserId],
      "new_conversation",
      conversation,
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
          conversationId: conversation.id,
          messageId: message.id,
        },
      );
    } catch (notifErr: any) {
      this.logger.warn(
        `Failed to dispatch message notification: ${notifErr?.message || notifErr}`,
      );
    }

    return message;
  }

  async createGroupConversation(
    creatorUserId: string,
    dto: CreateGroupConversationDto,
  ) {
    if (!dto.title || dto.title.trim().length === 0) {
      throw new BadRequestException("Group conversation title is required");
    }

    const uniqueParticipantIds = Array.from(
      new Set([...dto.participantUserIds, creatorUserId]),
    );

    if (uniqueParticipantIds.length < 2) {
      throw new BadRequestException(
        "A group conversation must have at least 2 unique participants",
      );
    }

    const creatorUser = await this.prisma.user.findUnique({
      where: { id: creatorUserId },
      include: { employeeProfile: true },
    });

    if (!creatorUser) {
      throw new NotFoundException("Creator user not found");
    }

    // Verify all participant users exist
    const existingUsers = await this.prisma.user.findMany({
      where: { id: { in: uniqueParticipantIds } },
      select: { id: true, role: true },
    });

    if (existingUsers.length !== uniqueParticipantIds.length) {
      throw new BadRequestException(
        "One or more participant users do not exist",
      );
    }

    const initialContent =
      dto.initialMessage ||
      `Group conversation "${dto.title}" created by ${creatorUser.employeeProfile?.firstName || creatorUser.email}`;

    const { conversation } =
      await this.messagingRepo.createConversationWithInitialMessage({
        title: dto.title.trim(),
        isGroup: true,
        createdByUserId: creatorUserId,
        participants: existingUsers.map((u) => ({
          userId: u.id,
          role: u.role,
        })),
        initialContent,
      });

    // Notify all participants
    const otherParticipantIds = uniqueParticipantIds.filter(
      (id) => id !== creatorUserId,
    );
    this.realtimeService.emitToUsers(
      otherParticipantIds,
      "new_conversation",
      conversation,
    );

    for (const pId of otherParticipantIds) {
      this.notificationsService
        .sendNotification(
          pId,
          `Added to group: ${dto.title}`,
          initialContent,
          NotificationType.CHAT_MESSAGE,
          { conversationId: conversation.id },
        )
        .catch(() => {});
    }

    return conversation;
  }

  async getUserConversations(userId: string) {
    return this.messagingRepo.getUserConversations(userId);
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
    const participant = await this.messagingRepo.findParticipant(
      conversationId,
      currentUserId,
    );

    if (!participant) {
      throw new ForbiddenException(
        "You are not an authorized participant in this conversation",
      );
    }

    return this.messagingRepo.findMessages(conversationId, query);
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
    const participant = await this.messagingRepo.findParticipant(
      conversationId,
      senderUserId,
    );

    if (!participant) {
      throw new ForbiddenException(
        "You are not a participant in this conversation",
      );
    }

    const senderUser = await this.prisma.user.findUnique({
      where: { id: senderUserId },
      include: { employeeProfile: true },
    });

    // 2. Persist Message & Update Conversation via repository
    const message = await this.messagingRepo.createMessage(
      conversationId,
      senderUserId,
      dto.content,
      dto.attachmentUrl,
    );

    await this.prisma.auditLog.create({
      data: {
        userId: senderUserId,
        action: AuditAction.MESSAGE_SENT,
        entity: "ChatMessage",
        entityId: message.id,
        payload: { conversationId },
      },
    });

    // 3. Real-Time Event Broadcast to room "conversation:{id}"
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
    const participant = await this.messagingRepo.findParticipant(
      conversationId,
      currentUserId,
    );

    if (!participant) {
      throw new ForbiddenException(
        "You are not a participant in this conversation",
      );
    }

    const result = await this.messagingRepo.markConversationRead(
      conversationId,
      currentUserId,
    );

    this.realtimeService.emitToConversation(conversationId, "messages_read", {
      conversationId,
      readByUserId: currentUserId,
      readAt: result.readAt,
    });

    return {
      message: "Conversation marked as read",
      markedCount: result.markedCount,
    };
  }

  async getUnreadMessageCount(userId: string) {
    const count = await this.messagingRepo.getUnreadMessageCount(userId);
    return { unreadCount: count };
  }

  async deleteMessage(messageId: string, currentUserId: string) {
    const message = await this.messagingRepo.findMessageById(messageId);

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

    await this.messagingRepo.softDeleteMessage(messageId, currentUserId);

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
