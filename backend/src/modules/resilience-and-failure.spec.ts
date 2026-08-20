import { Test, TestingModule } from "@nestjs/testing";
import { HttpStatus } from "@nestjs/common";
import { HealthController } from "./health/health.controller";
import { HealthCheckService, MemoryHealthIndicator } from "@nestjs/terminus";
import { PrismaService } from "../prisma/prisma.service";
import { RedisService } from "../common/redis/redis.service";
import { ConfigService } from "@nestjs/config";

describe("Production Resilience & Failure Injection Suite", () => {
  let healthController: HealthController;
  let prismaService: PrismaService;
  let redisService: RedisService;

  const mockPrisma: any = {
    $queryRaw: jest.fn(),
  };

  const mockRedis: any = {
    ping: jest.fn(),
    isAvailable: jest.fn(),
    get: jest.fn(),
    set: jest.fn(),
  };

  const mockHealthCheckService = {
    check: jest.fn((indicators) =>
      Promise.all(indicators.map((i: any) => i())),
    ),
  };

  const mockMemoryHealthIndicator = {
    checkHeap: jest.fn().mockReturnValue({ memory_heap: { status: "up" } }),
  };

  const mockConfigService = {
    get: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        { provide: HealthCheckService, useValue: mockHealthCheckService },
        { provide: MemoryHealthIndicator, useValue: mockMemoryHealthIndicator },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: RedisService, useValue: mockRedis },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    healthController = module.get<HealthController>(HealthController);
    prismaService = module.get<PrismaService>(PrismaService);
    redisService = module.get<RedisService>(RedisService);
    jest.clearAllMocks();
  });

  // ============================================================
  // 1. LIVENESS PROBE (Process alive without DB dependence)
  // ============================================================
  describe("Liveness Probe (/health/live)", () => {
    it("should return ok status and process uptime without touching the database", () => {
      const result = healthController.getLiveness();
      expect(result.status).toBe("ok");
      expect(result.uptimeSeconds).toBeGreaterThanOrEqual(0);
      expect(result.timestamp).toBeDefined();
      expect(mockPrisma.$queryRaw).not.toHaveBeenCalled();
    });
  });

  // ============================================================
  // 2. READINESS PROBE (Database and Dependency readiness)
  // ============================================================
  describe("Readiness Probe (/health/ready)", () => {
    it("should return 200 ready when database is connected", async () => {
      mockPrisma.$queryRaw.mockResolvedValue([{ "?column?": 1 }]);
      mockRedis.isAvailable.mockReturnValue(true);

      const mockRes: any = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn(),
      };

      await healthController.getReadiness(mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(HttpStatus.OK);
      expect(mockRes.send).toHaveBeenCalledWith(
        expect.objectContaining({
          status: "ready",
          database: "connected",
        }),
      );
    });

    it("should return 503 service unavailable when database connection fails", async () => {
      mockPrisma.$queryRaw.mockRejectedValue(
        new Error("Connection to PostgreSQL pool refused"),
      );

      const mockRes: any = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn(),
      };

      await healthController.getReadiness(mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(
        HttpStatus.SERVICE_UNAVAILABLE,
      );
      expect(mockRes.send).toHaveBeenCalledWith(
        expect.objectContaining({
          status: "not_ready",
          database: "disconnected",
        }),
      );
    });
  });

  // ============================================================
  // 3. DATABASE DEDICATED PROBE (/health/db)
  // ============================================================
  describe("Database Probe (/health/db)", () => {
    it("should return 200 with latencyMs when database query succeeds", async () => {
      mockPrisma.$queryRaw.mockResolvedValue([{ "?column?": 1 }]);

      const mockRes: any = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn(),
      };

      await healthController.getDbHealth(mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(HttpStatus.OK);
      expect(mockRes.send).toHaveBeenCalledWith(
        expect.objectContaining({
          status: "up",
        }),
      );
    });

    it("should return 503 down when database ping throws", async () => {
      mockPrisma.$queryRaw.mockRejectedValue(new Error("Timeout"));

      const mockRes: any = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn(),
      };

      await healthController.getDbHealth(mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(
        HttpStatus.SERVICE_UNAVAILABLE,
      );
      expect(mockRes.send).toHaveBeenCalledWith(
        expect.objectContaining({
          status: "down",
        }),
      );
    });
  });

  // ============================================================
  // 4. REDIS DEDICATED PROBE (/health/redis)
  // ============================================================
  describe("Redis Probe (/health/redis)", () => {
    it("should return 200 up when Redis responds to PING", async () => {
      mockRedis.ping.mockResolvedValue({ status: "up", latencyMs: 2 });

      const mockRes: any = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn(),
      };

      await healthController.getRedisHealth(mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(HttpStatus.OK);
      expect(mockRes.send).toHaveBeenCalledWith(
        expect.objectContaining({
          status: "up",
        }),
      );
    });

    it("should return 503 down when Redis is offline or degraded", async () => {
      mockRedis.ping.mockResolvedValue({ status: "down" });

      const mockRes: any = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn(),
      };

      await healthController.getRedisHealth(mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(
        HttpStatus.SERVICE_UNAVAILABLE,
      );
      expect(mockRes.send).toHaveBeenCalledWith(
        expect.objectContaining({
          status: "down",
        }),
      );
    });
  });

  // ============================================================
  // 5. REDIS SERVICE GRACEFUL DEGRADATION
  // ============================================================
  describe("Redis Graceful Fallback", () => {
    it("should return null for get when Redis is disconnected instead of throwing", async () => {
      const realRedisService = new RedisService(mockConfigService as any);
      const val = await realRedisService.get("some_key");
      expect(val).toBeNull();
    });

    it("should return false for set when Redis is disconnected instead of throwing", async () => {
      const realRedisService = new RedisService(mockConfigService as any);
      const result = await realRedisService.set("some_key", "value");
      expect(result).toBe(false);
    });
  });
});
