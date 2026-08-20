import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter } from 'events';

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
  private readonly emitter = new EventEmitter();

  constructor() {
    this.emitter.setMaxListeners(100);
  }

  /**
   * Broadcasts a real-time event to specific recipients or conversation channel
   */
  emitToUsers(userIds: string[], event: string, data: any) {
    try {
      const payload: RealTimeEventPayload = {
        channel: 'user_notifications',
        event,
        data,
        recipientUserIds: userIds,
        timestamp: new Date().toISOString(),
      };

      for (const userId of userIds) {
        this.emitter.emit(`user:${userId}`, payload);
      }

      this.logger.debug(`[RealTime] Emitted event '${event}' to ${userIds.length} user(s)`);
    } catch (err: any) {
      this.logger.warn(`[RealTime] Error emitting event to users: ${err?.message || err}`);
    }
  }

  /**
   * Broadcasts a real-time event to a conversation channel
   */
  emitToConversation(conversationId: string, event: string, data: any) {
    try {
      const payload: RealTimeEventPayload = {
        channel: `conversation:${conversationId}`,
        event,
        data,
        timestamp: new Date().toISOString(),
      };

      this.emitter.emit(`conversation:${conversationId}`, payload);
      this.logger.debug(`[RealTime] Emitted event '${event}' to conversation ${conversationId}`);
    } catch (err: any) {
      this.logger.warn(`[RealTime] Error emitting event to conversation: ${err?.message || err}`);
    }
  }

  /**
   * Subscribes a listener to a specific user's private event stream
   */
  subscribeUser(userId: string, listener: (payload: RealTimeEventPayload) => void) {
    this.emitter.on(`user:${userId}`, listener);
    return () => this.emitter.off(`user:${userId}`, listener);
  }

  /**
   * Subscribes a listener to a specific conversation stream
   */
  subscribeConversation(conversationId: string, listener: (payload: RealTimeEventPayload) => void) {
    this.emitter.on(`conversation:${conversationId}`, listener);
    return () => this.emitter.off(`conversation:${conversationId}`, listener);
  }
}
