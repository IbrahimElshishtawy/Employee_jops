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
import { SyncStatus, IntegrationStatus } from "@prisma/client";

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

  @Public()
  @Get("queues")
  @ApiOperation({ summary: "Offline Sync Queue and Background Workers monitoring (OPS-003)" })
  async getQueuesHealth(@Res() res: FastifyReply) {
    try {
      const [pendingCount, conflictCount, processedCount] = await Promise.all([
        this.prisma.offlineSyncQueue.count({ where: { status: SyncStatus.PENDING } }),
        this.prisma.offlineSyncQueue.count({ where: { status: SyncStatus.CONFLICT } }),
        this.prisma.offlineSyncQueue.count({ where: { status: SyncStatus.PROCESSED } }),
      ]);

      res.status(HttpStatus.OK).send({
        status: "healthy",
        offlineSyncQueue: {
          pending: pendingCount,
          conflict: conflictCount,
          processed: processedCount,
        },
        redisQueueStatus: this.redis.isAvailable() ? "active" : "degraded",
        timestamp: new Date().toISOString(),
      });
    } catch (err: any) {
      res.status(HttpStatus.INTERNAL_SERVER_ERROR).send({
        status: "error",
        error: err.message,
        timestamp: new Date().toISOString(),
      });
    }
  }

  @Public()
  @Get("integrations")
  @ApiOperation({ summary: "External integrations and webhook channel monitoring (OPS-004)" })
  async getIntegrationsHealth(@Res() res: FastifyReply) {
    try {
      const recentLogs = await this.prisma.integrationLog.findMany({
        take: 20,
        orderBy: { createdAt: "desc" },
      });

      const totalRecent = recentLogs.length;
      const failedRecent = recentLogs.filter((l) => l.status === IntegrationStatus.FAILED).length;
      const errorRatePercent = totalRecent > 0 ? (failedRecent / totalRecent) * 100 : 0;

      res.status(HttpStatus.OK).send({
        status: errorRatePercent < 20 ? "healthy" : "elevated_error_rate",
        totalEvaluated: totalRecent,
        failedCount: failedRecent,
        errorRatePercent,
        timestamp: new Date().toISOString(),
      });
    } catch (err: any) {
      res.status(HttpStatus.INTERNAL_SERVER_ERROR).send({
        status: "error",
        error: err.message,
        timestamp: new Date().toISOString(),
      });
    }
  }

  @Public()
  @Get("system")
  @ApiOperation({ summary: "Holistic system telemetry, CPU, memory, DB, and cache metrics" })
  async getSystemTelemetry(@Res() res: FastifyReply) {
    const memoryUsage = process.memoryUsage();
    res.status(HttpStatus.OK).send({
      status: "operational",
      uptimeSeconds: Math.floor(process.uptime()),
      nodeVersion: process.version,
      platform: process.platform,
      memory: {
        rssMb: Math.round(memoryUsage.rss / (1024 * 1024)),
        heapTotalMb: Math.round(memoryUsage.heapTotal / (1024 * 1024)),
        heapUsedMb: Math.round(memoryUsage.heapUsed / (1024 * 1024)),
      },
      timestamp: new Date().toISOString(),
    });
  }
}
