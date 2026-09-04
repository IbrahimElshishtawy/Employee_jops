import {
  Injectable,
  Logger,
  OnModuleInit,
  OnModuleDestroy,
  Optional,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { Server } from "socket.io";
import { EventEmitter } from "events";
import * as crypto from "crypto";
import Redis from "ioredis";

export interface RealTimeEventPayload {
  channel: string;
  event: string;
  data: any;
  recipientUserIds?: string[];
  conversationId?: string;
  senderInstanceId?: string;
  timestamp: string;
}

// Shared bus simulation for tests and fallback multi-instance coordination
class InProcessClusterBus extends EventEmitter {
  constructor() {
    super();
    this.setMaxListeners(200);
  }
}
const globalClusterBus = new InProcessClusterBus();

@Injectable()
export class RealTimeService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RealTimeService.name);
  private server: Server | null = null;
  private readonly localEmitter = new EventEmitter();
  readonly instanceId = crypto.randomUUID();

  private redisPub: Redis | null = null;
  private redisSub: Redis | null = null;
  private isRedisConnected = false;
  private readonly REDIS_CHANNEL = "cyberwise:realtime:events";

  constructor(@Optional() private readonly configService?: ConfigService) {
    this.localEmitter.setMaxListeners(100);

    // Always wire up the cluster bus to handle cross-instance routing
    globalClusterBus.on(this.REDIS_CHANNEL, (rawPayload: string) => {
      this.handleClusterMessage(rawPayload);
    });
  }

  onModuleInit() {
    const host = this.configService?.get<string>("redis.host") || "localhost";
    const port = this.configService?.get<number>("redis.port") || 6379;
    const password = this.configService?.get<string>("redis.password");

    if (
      process.env.NODE_ENV !== "test" &&
      process.env.DISABLE_REDIS !== "true"
    ) {
      try {
        this.redisPub = new Redis({
          host,
          port,
          password: password || undefined,
          lazyConnect: true,
          connectTimeout: 2000,
          maxRetriesPerRequest: 1,
          retryStrategy: () => null,
        });
        this.redisSub = new Redis({
          host,
          port,
          password: password || undefined,
          lazyConnect: true,
          connectTimeout: 2000,
          maxRetriesPerRequest: 1,
          retryStrategy: () => null,
        });

        Promise.all([this.redisPub.connect(), this.redisSub.connect()])
          .then(() => {
            this.isRedisConnected = true;
            this.redisSub?.subscribe(this.REDIS_CHANNEL, (err) => {
              if (err) {
                this.logger.warn(`Failed to subscribe to Redis realtime channel: ${err.message}`);
              } else {
                this.logger.log(`[RealTime] Subscribed to distributed Redis channel: ${this.REDIS_CHANNEL}`);
              }
            });

            this.redisSub?.on("message", (channel, message) => {
              if (channel === this.REDIS_CHANNEL) {
                this.handleClusterMessage(message);
              }
            });
          })
          .catch(() => {
            this.isRedisConnected = false;
            this.logger.warn(
              `[RealTime] Redis unavailable. Using cluster event bus fallback for real-time distribution.`,
            );
          });
      } catch (err: any) {
        this.isRedisConnected = false;
        this.logger.warn(`[RealTime] Redis init error: ${err.message}`);
      }
    }
  }

  async onModuleDestroy() {
    if (this.redisPub) {
      try {
        await this.redisPub.quit();
      } catch {
        this.redisPub.disconnect();
      }
    }
    if (this.redisSub) {
      try {
        await this.redisSub.quit();
      } catch {
        this.redisSub.disconnect();
      }
    }
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
        senderInstanceId: this.instanceId,
        timestamp: new Date().toISOString(),
      };

      // 1. Deliver locally
      this.dispatchLocalUserEvent(userIds, event, data, payload);

      // 2. Publish to distributed cluster bus
      this.publishToCluster(payload);

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
        conversationId,
        senderInstanceId: this.instanceId,
        timestamp: new Date().toISOString(),
      };

      // 1. Deliver locally
      this.dispatchLocalConversationEvent(conversationId, event, data, payload);

      // 2. Publish to distributed cluster bus
      this.publishToCluster(payload);

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
  notifyPresenceChange(
    userId: string,
    isOnline: boolean,
    targetUserIds?: string[],
  ) {
    const event = isOnline ? "user_online" : "user_offline";
    const data = {
      userId,
      status: isOnline ? "ONLINE" : "OFFLINE",
      timestamp: new Date().toISOString(),
    };

    if (targetUserIds && targetUserIds.length > 0) {
      this.emitToUsers(targetUserIds, event, data);
    } else if (this.server) {
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
    return () =>
      this.localEmitter.off(`conversation:${conversationId}`, listener);
  }

  // ----------------------------------------------------
  // Internal Cluster Coordination Helpers
  // ----------------------------------------------------
  private publishToCluster(payload: RealTimeEventPayload) {
    const serialized = JSON.stringify(payload);

    if (this.isRedisConnected && this.redisPub) {
      this.redisPub.publish(this.REDIS_CHANNEL, serialized).catch(() => null);
    } else {
      globalClusterBus.emit(this.REDIS_CHANNEL, serialized);
    }
  }

  private handleClusterMessage(raw: string) {
    try {
      const payload: RealTimeEventPayload = JSON.parse(raw);
      // Skip echo messages that this instance originated
      if (payload.senderInstanceId === this.instanceId) {
        return;
      }

      if (payload.recipientUserIds && payload.recipientUserIds.length > 0) {
        this.dispatchLocalUserEvent(
          payload.recipientUserIds,
          payload.event,
          payload.data,
          payload,
        );
      } else if (payload.conversationId) {
        this.dispatchLocalConversationEvent(
          payload.conversationId,
          payload.event,
          payload.data,
          payload,
        );
      }
    } catch (err: any) {
      this.logger.warn(`Failed to parse cluster realtime payload: ${err.message}`);
    }
  }

  private dispatchLocalUserEvent(
    userIds: string[],
    event: string,
    data: any,
    payload: RealTimeEventPayload,
  ) {
    if (this.server) {
      for (const userId of userIds) {
        this.server.to(`user:${userId}`).emit(event, data);
      }
    }
    for (const userId of userIds) {
      this.localEmitter.emit(`user:${userId}`, payload);
    }
  }

  private dispatchLocalConversationEvent(
    conversationId: string,
    event: string,
    data: any,
    payload: RealTimeEventPayload,
  ) {
    if (this.server) {
      this.server.to(`conversation:${conversationId}`).emit(event, data);
    }
    this.localEmitter.emit(`conversation:${conversationId}`, payload);
  }
}
