import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayInit,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from "@nestjs/websockets";
import { Logger } from "@nestjs/common";
import { Server, Socket } from "socket.io";
import { PresenceService } from "./presence.service";
import { RealTimeService } from "./realtime.service";
import { WsJwtGuard } from "./guards/ws-jwt.guard";
import { PrismaService } from "../../prisma/prisma.service";
import {
  JoinConversationWsDto,
  LeaveConversationWsDto,
  TypingWsDto,
} from "./dto";

@WebSocketGateway({
  cors: {
    origin: "*",
    credentials: true,
  },
  namespace: "/realtime",
})
export class RealTimeGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(RealTimeGateway.name);

  // Injected services
  constructor(
    private readonly presenceService: PresenceService,
    private readonly realtimeService: RealTimeService,
    private readonly wsJwtGuard: WsJwtGuard,
    private readonly prisma: PrismaService,
  ) {}

  afterInit(server: Server) {
    this.realtimeService.setServer(server);
    this.logger.log(
      "⚡ RealTime Socket.IO Gateway initialized on namespace /realtime",
    );
  }

  async handleConnection(client: Socket) {
    try {
      // 1. Authenticate connection handshake
      const user = await this.wsJwtGuard.authenticateSocket(client);
      client.data.user = user;

      // 2. Join user's personal notification room: "user:{userId}"
      await client.join(`user:${user.id}`);

      // 3. Mark user presence online
      const isFirst = this.presenceService.markUserOnline(user.id, client.id);
      if (isFirst) {
        this.realtimeService.notifyPresenceChange(user.id, true);
      }

      client.emit("connected", {
        status: "AUTHENTICATED",
        userId: user.id,
        role: user.role,
        timestamp: new Date().toISOString(),
      });

      this.logger.log(
        `[WS] Client connected & authenticated: user=${user.id} socket=${client.id}`,
      );
    } catch (err: any) {
      this.logger.warn(`[WS] Connection rejected: ${err?.message || err}`);
      client.emit("error", {
        code: "UNAUTHORIZED",
        message: err?.message || "Authentication failed",
      });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    const user = client.data?.user;
    if (user && user.id) {
      const isOffline = this.presenceService.markUserOffline(
        user.id,
        client.id,
      );
      if (isOffline) {
        this.realtimeService.notifyPresenceChange(user.id, false);
      }
      this.logger.log(
        `[WS] Client disconnected: user=${user.id} socket=${client.id}`,
      );
    }
  }

  // ============================================================
  // CONVERSATION ROOMS & ZERO-TRUST ACCESS
  // ============================================================

  @SubscribeMessage("join_conversation")
  async handleJoinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: JoinConversationWsDto,
  ) {
    const user = client.data.user;
    if (!user) {
      client.emit("error", { message: "Unauthenticated socket session" });
      return;
    }

    // Zero-Trust: Verify user is a registered participant in this conversation
    const isParticipant = await this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: {
          conversationId: dto.conversationId,
          userId: user.id,
        },
      },
    });

    if (!isParticipant) {
      this.logger.warn(
        `[WS] Unauthorized join attempt: user ${user.id} on conv ${dto.conversationId}`,
      );
      client.emit("error", {
        code: "FORBIDDEN",
        message: "You are not an authorized participant in this conversation",
      });
      return;
    }

    await client.join(`conversation:${dto.conversationId}`);
    client.emit("joined_conversation", {
      conversationId: dto.conversationId,
      status: "SUCCESS",
    });

    this.logger.debug(
      `[WS] User ${user.id} joined room conversation:${dto.conversationId}`,
    );
  }

  @SubscribeMessage("leave_conversation")
  async handleLeaveConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: LeaveConversationWsDto,
  ) {
    await client.leave(`conversation:${dto.conversationId}`);
    client.emit("left_conversation", {
      conversationId: dto.conversationId,
      status: "SUCCESS",
    });
  }

  // ============================================================
  // EPHEMERAL TYPING INDICATORS (Zero DB writes)
  // ============================================================

  @SubscribeMessage("typing_start")
  handleTypingStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: TypingWsDto,
  ) {
    const user = client.data.user;
    if (!user || !dto.conversationId) return;

    client.to(`conversation:${dto.conversationId}`).emit("user_typing", {
      conversationId: dto.conversationId,
      userId: user.id,
      userName: user.name,
    });
  }

  @SubscribeMessage("typing_stop")
  handleTypingStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: TypingWsDto,
  ) {
    const user = client.data.user;
    if (!user || !dto.conversationId) return;

    client.to(`conversation:${dto.conversationId}`).emit("user_stop_typing", {
      conversationId: dto.conversationId,
      userId: user.id,
    });
  }
}
