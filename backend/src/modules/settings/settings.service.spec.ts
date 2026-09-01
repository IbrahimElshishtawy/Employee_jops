import { Test, TestingModule } from "@nestjs/testing";
import { SettingsService } from "./settings.service";
import { PrismaService } from "../../prisma/prisma.service";
import { RedisService } from "../../common/redis/redis.service";
import { ConflictException, NotFoundException } from "@nestjs/common";
import { SettingCategory } from "@prisma/client";

describe("SettingsService", () => {
  let service: SettingsService;
  let prisma: PrismaService;
  let redis: RedisService;

  const mockPrismaService = {
    systemSetting: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      upsert: jest.fn(),
      delete: jest.fn(),
    },
    featureFlag: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
  };

  const mockRedisService = {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SettingsService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    service = module.get<SettingsService>(SettingsService);
    prisma = module.get<PrismaService>(PrismaService);
    redis = module.get<RedisService>(RedisService);
    jest.clearAllMocks();
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  describe("getSetting", () => {
    it("should return cached setting if available in redis", async () => {
      mockRedisService.get.mockResolvedValue(JSON.stringify(15));

      const val = await service.getSetting(
        "attendance_grace_period_minutes",
        10,
      );
      expect(val).toBe(15);
      expect(mockPrismaService.systemSetting.findUnique).not.toHaveBeenCalled();
    });

    it("should query DB and cache value on cache miss", async () => {
      mockRedisService.get.mockResolvedValue(null);
      mockPrismaService.systemSetting.findUnique.mockResolvedValue({
        id: "s-1",
        key: "attendance_grace_period_minutes",
        value: 20,
      });

      const val = await service.getSetting(
        "attendance_grace_period_minutes",
        10,
      );
      expect(val).toBe(20);
      expect(mockRedisService.set).toHaveBeenCalledWith(
        "setting:attendance_grace_period_minutes",
        JSON.stringify(20),
        300,
      );
    });
  });

  describe("setSetting", () => {
    it("should upsert setting, invalidate redis cache, and record audit log", async () => {
      mockPrismaService.systemSetting.upsert.mockResolvedValue({
        id: "s-1",
        key: "company_name",
        value: "CyberWise Hospitality",
        category: SettingCategory.GENERAL,
      });
      mockPrismaService.auditLog.create.mockResolvedValue({});

      const res = await service.setSetting(
        {
          key: "company_name",
          value: "CyberWise Hospitality",
          category: SettingCategory.GENERAL,
        },
        "admin-id",
      );

      expect(res.key).toBe("company_name");
      expect(mockRedisService.del).toHaveBeenCalledWith("setting:company_name");
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("isFeatureEnabled", () => {
    it("should return cached feature flag state", async () => {
      mockRedisService.get.mockResolvedValue("true");

      const isEnabled = await service.isFeatureEnabled("enable_biometrics");
      expect(isEnabled).toBe(true);
      expect(mockPrismaService.featureFlag.findUnique).not.toHaveBeenCalled();
    });

    it("should query DB if not cached and cache it", async () => {
      mockRedisService.get.mockResolvedValue(null);
      mockPrismaService.featureFlag.findUnique.mockResolvedValue({
        id: "f-1",
        key: "enable_biometrics",
        isEnabled: true,
      });

      const isEnabled = await service.isFeatureEnabled("enable_biometrics");
      expect(isEnabled).toBe(true);
      expect(mockRedisService.set).toHaveBeenCalledWith(
        "feature_flag:enable_biometrics",
        "true",
        60,
      );
    });
  });
});
