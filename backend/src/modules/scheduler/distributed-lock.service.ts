import {
  Injectable,
  Logger,
  OnModuleInit,
  OnModuleDestroy,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import Redis from "ioredis";
import * as crypto from "crypto";

export interface LockResult {
  acquired: boolean;
  token: string;
}

@Injectable()
export class DistributedLockService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DistributedLockService.name);
  private redisClient: Redis | null = null;
  private isRedisConnected = false;

  // In-process fallback lock registry when Redis is unavailable
  private readonly localLocks: Map<
    string,
    { token: string; expiresAt: number }
  > = new Map();

  constructor(private readonly configService: ConfigService) {}

  onModuleInit() {
    const host = this.configService.get<string>("redis.host") || "localhost";
    const port = this.configService.get<number>("redis.port") || 6379;
    const password = this.configService.get<string>("redis.password");

    // Only attempt Redis connection if not explicitly disabled
    if (process.env.NODE_ENV !== "test" && process.env.DISABLE_REDIS !== "true") {
      try {
        this.redisClient = new Redis({
          host,
          port,
          password: password || undefined,
          lazyConnect: true,
          connectTimeout: 2000,
          maxRetriesPerRequest: 1,
          retryStrategy: () => null, // Do not spam reconnects if Redis is down
        });

        this.redisClient
          .connect()
          .then(() => {
            this.isRedisConnected = true;
            this.logger.log(`[DistributedLock] Connected to Redis at ${host}:${port}`);
          })
          .catch(() => {
            this.isRedisConnected = false;
            this.logger.warn(
              `[DistributedLock] Redis connection failed at ${host}:${port}. Using local memory lock fallback.`,
            );
          });
      } catch (err: any) {
        this.isRedisConnected = false;
        this.logger.warn(
          `[DistributedLock] Redis initialization error: ${err.message}. Using local memory lock fallback.`,
        );
      }
    }
  }

  async onModuleDestroy() {
    if (this.redisClient) {
      try {
        await this.redisClient.quit();
      } catch {
        this.redisClient.disconnect();
      }
    }
  }

  /**
   * Acquire a distributed lock for a specific key with a TTL in milliseconds.
   * Returns { acquired: true, token } if successful, or { acquired: false, token: '' } if already held.
   */
  async acquireLock(
    lockKey: string,
    ttlMs: number = 30000,
  ): Promise<LockResult> {
    const token = crypto.randomUUID();
    const fullKey = `lock:${lockKey}`;

    if (this.isRedisConnected && this.redisClient) {
      try {
        // Atomic SET lock:name token PX ttlMs NX
        const result = await this.redisClient.set(
          fullKey,
          token,
          "PX",
          ttlMs,
          "NX",
        );
        if (result === "OK") {
          return { acquired: true, token };
        }
        return { acquired: false, token: "" };
      } catch (err: any) {
        this.logger.warn(
          `[DistributedLock] Redis set failed: ${err.message}. Falling back to local lock.`,
        );
      }
    }

    // Local in-memory lock fallback
    const now = Date.now();
    const current = this.localLocks.get(fullKey);
    if (current && current.expiresAt > now) {
      return { acquired: false, token: "" };
    }

    this.localLocks.set(fullKey, { token, expiresAt: now + ttlMs });
    return { acquired: true, token };
  }

  /**
   * Release a distributed lock atomically using Lua script to verify token ownership.
   */
  async releaseLock(lockKey: string, token: string): Promise<boolean> {
    const fullKey = `lock:${lockKey}`;

    if (this.isRedisConnected && this.redisClient) {
      try {
        // Atomic Lua script: only delete if the token matches
        const luaScript = `
          if redis.call("get", KEYS[1]) == ARGV[1] then
            return redis.call("del", KEYS[1])
          else
            return 0
          end
        `;
        const result = await this.redisClient.eval(luaScript, 1, fullKey, token);
        return result === 1;
      } catch (err: any) {
        this.logger.warn(`[DistributedLock] Redis release failed: ${err.message}`);
      }
    }

    // Local in-memory release
    const current = this.localLocks.get(fullKey);
    if (current && current.token === token) {
      this.localLocks.delete(fullKey);
      return true;
    }
    return false;
  }

  /**
   * Executes an asynchronous task inside a distributed lock.
   * If another instance holds the lock, skips execution and returns skippedReason.
   */
  async withLock<T>(
    lockKey: string,
    ttlMs: number,
    fn: () => Promise<T>,
  ): Promise<{
    executed: boolean;
    result?: T;
    skippedReason?: string;
  }> {
    const lock = await this.acquireLock(lockKey, ttlMs);
    if (!lock.acquired) {
      this.logger.debug(
        `[DistributedLock] Execution skipped for '${lockKey}': locked by another instance`,
      );
      return {
        executed: false,
        skippedReason: "LOCKED_BY_ANOTHER_INSTANCE",
      };
    }

    try {
      const result = await fn();
      return { executed: true, result };
    } finally {
      await this.releaseLock(lockKey, lock.token);
    }
  }
}
