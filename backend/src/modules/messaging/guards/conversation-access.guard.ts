import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  NotFoundException,
} from "@nestjs/common";
import { PrismaService } from "../../../prisma/prisma.service";
import { Role } from "@prisma/client";

@Injectable()
export class ConversationAccessGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    if (!user || !user.id) {
      throw new ForbiddenException("Authentication required");
    }

    const conversationId =
      request.params.id ||
      request.params.conversationId ||
      request.body?.conversationId;

    if (!conversationId) {
      return true; // No conversation ID to protect in this specific route
    }

    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        participants: {
          select: { userId: true },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException("Conversation not found");
    }

    const isParticipant = conversation.participants.some(
      (p) => p.userId === user.id,
    );

    const isElevatedAdmin =
      user.role === Role.SUPER_ADMIN || user.role === Role.HR_ADMIN;

    if (!isParticipant && !isElevatedAdmin) {
      throw new ForbiddenException(
        "You do not have authorization to access this conversation",
      );
    }

    request.conversation = conversation;
    return true;
  }
}
