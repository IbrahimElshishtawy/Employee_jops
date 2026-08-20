import { Controller, Get, HttpStatus, Res } from "@nestjs/common";
import { ApiOperation, ApiTags, ApiResponse } from "@nestjs/swagger";
import {
  HealthCheck,
  HealthCheckService,
  MemoryHealthIndicator,
} from "@nestjs/terminus";
import { FastifyReply } from "fastify";
import { Public } from "../../common/decorators/public.decorator";
import { PrismaService } from "../../prisma/prisma.service";
import { RedisService } from "../../common/redis/redis.service";

@ApiTags("Health")
@Controller("health")
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private memory: MemoryHealthIndicator,
    private prisma: PrismaService,
    private redis: RedisService,
  ) {}

  @Public()
  @Get()
  @HealthCheck()
  @ApiOperation({ summary: "System overall health status" })
  async check() {
    return this.health.check([
      async () => {
        try {
          await this.prisma.$queryRaw`SELECT 1`;
          return { database: { status: "up" } };
        } catch (error: any) {
          return { database: { status: "down", message: error.message } };
        }
      },
      () => this.memory.checkHeap("memory_heap", 300 * 1024 * 1024),
    ]);
  }

  @Public()
  @Get("live")
  @ApiOperation({ summary: "Liveness probe (Is process alive?)" })
  @ApiResponse({ status: 200, description: "Process is alive" })
  getLiveness() {
    return {
      status: "ok",
      uptimeSeconds: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
    };
  }

  @Public()
  @Get("ready")
  @ApiOperation({ summary: "Readiness probe (Can instance accept traffic?)" })
  async getReadiness(@Res() res: FastifyReply) {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      res.status(HttpStatus.OK).send({
        status: "ready",
        database: "connected",
        redis: this.redis.isAvailable() ? "connected" : "degraded",
        timestamp: new Date().toISOString(),
      });
    } catch (err: any) {
      res.status(HttpStatus.SERVICE_UNAVAILABLE).send({
        status: "not_ready",
        database: "disconnected",
        error: err.message,
        timestamp: new Date().toISOString(),
      });
    }
  }

  @Public()
  @Get("db")
  @ApiOperation({ summary: "PostgreSQL Database Connectivity probe" })
  async getDbHealth(@Res() res: FastifyReply) {
    const start = Date.now();
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      res.status(HttpStatus.OK).send({
        status: "up",
        latencyMs: Date.now() - start,
        timestamp: new Date().toISOString(),
      });
    } catch (err: any) {
      res.status(HttpStatus.SERVICE_UNAVAILABLE).send({
        status: "down",
        error: err.message,
        timestamp: new Date().toISOString(),
      });
    }
  }

  @Public()
  @Get("redis")
  @ApiOperation({ summary: "Redis Cache & Rate Limiting probe" })
  async getRedisHealth(@Res() res: FastifyReply) {
    const health = await this.redis.ping();
    if (health.status === "up") {
      res.status(HttpStatus.OK).send({
        status: "up",
        latencyMs: health.latencyMs,
        timestamp: new Date().toISOString(),
      });
    } else {
      res.status(HttpStatus.SERVICE_UNAVAILABLE).send({
        status: "down",
        message: "Redis is unavailable or degraded",
        timestamp: new Date().toISOString(),
      });
    }
  }
}
