import { Injectable, Logger } from "@nestjs/common";

@Injectable()
export class PresenceService {
  private readonly logger = new Logger(PresenceService.name);

  // In-memory mapping: userId -> Set of active socket IDs
  // Low RAM footprint, O(1) lookups, Zero PostgreSQL writes
  private readonly userSockets = new Map<string, Set<string>>();

  /**
   * Registers a socket connection for a user.
   * Returns true if user just transitioned from offline to online.
   */
  markUserOnline(userId: string, socketId: string): boolean {
    let sockets = this.userSockets.get(userId);
    const isFirstConnection = !sockets || sockets.size === 0;

    if (!sockets) {
      sockets = new Set<string>();
      this.userSockets.set(userId, sockets);
    }
    sockets.add(socketId);

    this.logger.debug(
      `[Presence] User ${userId} connected (socket: ${socketId}). Total sockets: ${sockets.size}`,
    );

    return isFirstConnection;
  }

  /**
   * Unregisters a socket connection for a user.
   * Returns true if user transitioned from online to completely offline.
   */
  markUserOffline(userId: string, socketId: string): boolean {
    const sockets = this.userSockets.get(userId);
    if (!sockets) return false;

    sockets.delete(socketId);

    if (sockets.size === 0) {
      this.userSockets.delete(userId);
      this.logger.debug(`[Presence] User ${userId} is now offline.`);
      return true;
    }

    this.logger.debug(
      `[Presence] User ${userId} socket ${socketId} disconnected. Remaining: ${sockets.size}`,
    );
    return false;
  }

  /**
   * Checks whether a user currently has at least one active socket.
   */
  isUserOnline(userId: string): boolean {
    const sockets = this.userSockets.get(userId);
    return Boolean(sockets && sockets.size > 0);
  }

  /**
   * Returns array of user IDs that are currently online out of the provided list.
   */
  getOnlineUserIds(userIds: string[]): string[] {
    return userIds.filter((id) => this.isUserOnline(id));
  }

  /**
   * Retrieves all socket IDs for a given user.
   */
  getUserSocketIds(userId: string): string[] {
    const sockets = this.userSockets.get(userId);
    return sockets ? Array.from(sockets) : [];
  }

  /**
   * Returns the count of unique online users.
   */
  getActiveUserCount(): number {
    return this.userSockets.size;
  }

  /**
   * Clears in-memory presence state (useful for test resets).
   */
  reset(): void {
    this.userSockets.clear();
  }
}
