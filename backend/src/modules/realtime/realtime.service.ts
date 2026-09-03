import { Injectable, Logger } from "@nestjs/common";
import { Server } from "socket.io";
import { EventEmitter } from "events";

export interface RealTimeEventPayload {
  channel: string;
  event: string;
  data: any;
  recipientUserIds?: string[];
  timestamp: string;
}

@Injectable()
export class RealTimeService {
  private readonly logger = new Logger(RealTimeService.name);
  private server: Server | null = null;
  private readonly localEmitter = new EventEmitter();

  constructor() {
    this.localEmitter.setMaxListeners(100);
  }

  /**
   * Sets the Socket.IO Server reference from the WebSocket gateway.
   */
  setServer(server: Server) {
    this.server = server;
    this.logger.log("[RealTime] Socket.IO server reference registered.");
  }

  /**
   * Emits a real-time event to a single user's private room.
   */
  emitToUser(userId: string, event: string, data: any) {
    this.emitToUsers([userId], event, data);
  }

  /**
   * Emits a real-time event to specific users' private rooms: "user:{userId}".
   */
  emitToUsers(userIds: string[], event: string, data: any) {
    try {
      const payload: RealTimeEventPayload = {
        channel: "user_notifications",
        event,
        data,
        recipientUserIds: userIds,
        timestamp: new Date().toISOString(),
      };

      // 1. Socket.IO Room broadcast
      if (this.server) {
        for (const userId of userIds) {
          this.server.to(`user:${userId}`).emit(event, data);
        }
      }

      // 2. In-process event emitter fallback (for local subscribers)
      for (const userId of userIds) {
        this.localEmitter.emit(`user:${userId}`, payload);
      }

      this.logger.debug(
        `[RealTime] Emitted event '${event}' to ${userIds.length} user(s)`,
      );
    } catch (err: any) {
      this.logger.warn(
        `[RealTime] Error emitting event to users: ${err?.message || err}`,
      );
    }
  }

  /**
   * Emits a real-time event to a specific conversation room: "conversation:{conversationId}".
   */
  emitToConversation(conversationId: string, event: string, data: any) {
    try {
      const payload: RealTimeEventPayload = {
        channel: `conversation:${conversationId}`,
        event,
        data,
        timestamp: new Date().toISOString(),
      };

      // 1. Socket.IO Room broadcast
      if (this.server) {
        this.server.to(`conversation:${conversationId}`).emit(event, data);
      }

      // 2. In-process emitter fallback
      this.localEmitter.emit(`conversation:${conversationId}`, payload);

      this.logger.debug(
        `[RealTime] Emitted event '${event}' to conversation ${conversationId}`,
      );
    } catch (err: any) {
      this.logger.warn(
        `[RealTime] Error emitting event to conversation: ${err?.message || err}`,
      );
    }
  }

  /**
   * Emits presence status change (online/offline) to relevant rooms or users.
   */
  notifyPresenceChange(userId: string, isOnline: boolean, targetUserIds?: string[]) {
    const event = isOnline ? "user_online" : "user_offline";
    const data = { userId, status: isOnline ? "ONLINE" : "OFFLINE", timestamp: new Date().toISOString() };

    if (targetUserIds && targetUserIds.length > 0) {
      this.emitToUsers(targetUserIds, event, data);
    } else if (this.server) {
      // Lightweight presence event
      this.server.emit("presence_change", data);
    }
  }

  /**
   * Subscribes an in-process listener to a user's private event stream (backward-compatibility).
   */
  subscribeUser(
    userId: string,
    listener: (payload: RealTimeEventPayload) => void,
  ) {
    this.localEmitter.on(`user:${userId}`, listener);
    return () => this.localEmitter.off(`user:${userId}`, listener);
  }

  /**
   * Subscribes an in-process listener to a conversation stream.
   */
  subscribeConversation(
    conversationId: string,
    listener: (payload: RealTimeEventPayload) => void,
  ) {
    this.localEmitter.on(`conversation:${conversationId}`, listener);
    return () => this.localEmitter.off(`conversation:${conversationId}`, listener);
  }
}
