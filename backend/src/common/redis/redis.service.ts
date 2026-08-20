import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import Redis from "ioredis";

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis | null = null;
  private isConnected = false;

  constructor(private readonly configService: ConfigService) {}

  async onModuleInit() {
    const host = this.configService.get<string>("redis.host") || "localhost";
    const port = this.configService.get<number>("redis.port") || 6379;
    const password = this.configService.get<string>("redis.password");

    try {
      this.client = new Redis({
        host,
        port,
        password: password || undefined,
        lazyConnect: true,
        maxRetriesPerRequest: 1,
        retryStrategy: (times) => {
          if (times > 3) {
            this.logger.warn(
              `⚠️ Redis connection failed after ${times} attempts. Degrading gracefully to memory fallback.`,
            );
            return null; // Stop retrying
          }
          return Math.min(times * 200, 1000);
        },
      });

      this.client.on("connect", () => {
        this.isConnected = true;
        this.logger.log(` Connected to Redis on ${host}:${port}`);
      });

      this.client.on("error", (err) => {
        this.isConnected = false;
        this.logger.warn(`⚠️ Redis error: ${err.message}`);
      });

      this.client.on("close", () => {
        this.isConnected = false;
      });

      await this.client.connect().catch((err) => {
        this.isConnected = false;
        this.logger.warn(
          `⚠️ Redis is currently unavailable (${err.message}). Application will operate in resilient degraded mode.`,
        );
      });
    } catch (err: any) {
      this.isConnected = false;
      this.logger.warn(`⚠️ Failed to initialize Redis client: ${err.message}`);
    }
  }

  async onModuleDestroy() {
    if (this.client) {
      try {
        await this.client.quit();
        this.logger.log(" Disconnected from Redis");
      } catch {
        this.client.disconnect();
      }
    }
  }

  async ping(): Promise<{ status: "up" | "down"; latencyMs?: number }> {
    if (!this.client || !this.isConnected) {
      return { status: "down" };
    }
    const start = Date.now();
    try {
      const res = await this.client.ping();
      return res === "PONG"
        ? { status: "up", latencyMs: Date.now() - start }
        : { status: "down" };
    } catch {
      return { status: "down" };
    }
  }

  async get(key: string): Promise<string | null> {
    if (!this.client || !this.isConnected) return null;
    try {
      return await this.client.get(key);
    } catch (err: any) {
      this.logger.warn(`Redis GET error for key ${key}: ${err.message}`);
      return null;
    }
  }

  async set(key: string, value: string, ttlSeconds?: number): Promise<boolean> {
    if (!this.client || !this.isConnected) return false;
    try {
      if (ttlSeconds) {
        await this.client.set(key, value, "EX", ttlSeconds);
      } else {
        await this.client.set(key, value);
      }
      return true;
    } catch (err: any) {
      this.logger.warn(`Redis SET error for key ${key}: ${err.message}`);
      return false;
    }
  }

  async del(key: string): Promise<boolean> {
    if (!this.client || !this.isConnected) return false;
    try {
      await this.client.del(key);
      return true;
    } catch (err: any) {
      this.logger.warn(`Redis DEL error for key ${key}: ${err.message}`);
      return false;
    }
  }

  isAvailable(): boolean {
    return this.isConnected;
  }
}
