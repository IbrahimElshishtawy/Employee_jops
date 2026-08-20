import { Injectable, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";

@Injectable()
export class MessagesService {
  constructor(private prisma: PrismaService) {}

  async getUserConversations(userId: string) {
    return this.prisma.conversation.findMany({
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
                    firstName: true,
                    lastName: true,
                    avatarUrl: true,
                    jobTitle: true,
                  },
                },
              },
            },
          },
        },
        messages: {
          take: 1,
          orderBy: { createdAt: "desc" },
        },
      },
      orderBy: { updatedAt: "desc" },
    });
  }

  async getMessages(conversationId: string, limit = 50) {
    return this.prisma.chatMessage.findMany({
      where: { conversationId },
      include: {
        sender: {
          select: {
            id: true,
            email: true,
            employeeProfile: {
              select: { firstName: true, lastName: true, avatarUrl: true },
            },
          },
        },
      },
      orderBy: { createdAt: "asc" },
      take: limit,
    });
  }

  async sendMessage(
    conversationId: string,
    senderId: string,
    content: string,
    attachmentUrl?: string,
  ) {
    const message = await this.prisma.chatMessage.create({
      data: {
        conversationId,
        senderId,
        content,
        attachmentUrl,
      },
    });

    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });

    return message;
  }
}
