import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { Prisma, Role } from "@prisma/client";
import { QueryMessagesDto } from "./dto";

@Injectable()
export class MessagingRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findDirectConversation(userAId: string, userBId: string) {
    return this.prisma.conversation.findFirst({
      where: {
        isGroup: false,
        AND: [
          { participants: { some: { userId: userAId } } },
          { participants: { some: { userId: userBId } } },
        ],
      },
      include: {
        participants: true,
      },
    });
  }

  async findConversationById(conversationId: string) {
    return this.prisma.conversation.findUnique({
      where: { id: conversationId },
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
                    departmentId: true,
                  },
                },
              },
            },
          },
        },
      },
    });
  }

  async findParticipant(conversationId: string, userId: string) {
    return this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: {
          conversationId,
          userId,
        },
      },
      include: {
        conversation: {
          include: {
            participants: {
              select: { userId: true },
            },
          },
        },
      },
    });
  }

  async createConversationWithInitialMessage(params: {
    title?: string;
    isGroup: boolean;
    createdByUserId: string;
    participants: { userId: string; role?: Role }[];
    initialContent: string;
    attachmentUrl?: string;
  }) {
    return this.prisma.$transaction(async (tx) => {
      const conv = await tx.conversation.create({
        data: {
          title: params.title,
          isGroup: params.isGroup,
          createdByUserId: params.createdByUserId,
          lastMessageAt: new Date(),
        },
      });

      // Insert all participants
      await tx.conversationParticipant.createMany({
        data: params.participants.map((p) => ({
          conversationId: conv.id,
          userId: p.userId,
          role: p.role || Role.EMPLOYEE,
          lastReadAt: p.userId === params.createdByUserId ? new Date() : null,
        })),
      });

      // Insert initial message
      const msg = await tx.chatMessage.create({
        data: {
          conversationId: conv.id,
          senderId: params.createdByUserId,
          content: params.initialContent.trim(),
          attachmentUrl: params.attachmentUrl,
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

      return { conversation: conv, message: msg };
    });
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

    return Promise.all(
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
  }

  async findMessages(
    conversationId: string,
    query: Partial<QueryMessagesDto> = {},
  ) {
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

  async createMessage(
    conversationId: string,
    senderId: string,
    content: string,
    attachmentUrl?: string,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const msg = await tx.chatMessage.create({
        data: {
          conversationId,
          senderId,
          content: content.trim(),
          attachmentUrl,
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

      return msg;
    });
  }

  async markConversationRead(conversationId: string, userId: string) {
    const now = new Date();

    const [updateResult] = await Promise.all([
      this.prisma.chatMessage.updateMany({
        where: {
          conversationId,
          senderId: { not: userId },
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
            userId,
          },
        },
        data: { lastReadAt: now },
      }),
    ]);

    return {
      markedCount: updateResult.count,
      readAt: now,
    };
  }

  async getUnreadMessageCount(userId: string): Promise<number> {
    return this.prisma.chatMessage.count({
      where: {
        conversation: {
          participants: { some: { userId } },
        },
        senderId: { not: userId },
        isRead: false,
        isDeleted: false,
      },
    });
  }

  async findMessageById(messageId: string) {
    return this.prisma.chatMessage.findUnique({
      where: { id: messageId },
    });
  }

  async softDeleteMessage(messageId: string, currentUserId: string) {
    return this.prisma.chatMessage.update({
      where: { id: messageId },
      data: {
        isDeleted: true,
        deletedAt: new Date(),
        deletedById: currentUserId,
      },
    });
  }
}
