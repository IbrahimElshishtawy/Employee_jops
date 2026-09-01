import { Test, TestingModule } from "@nestjs/testing";
import { Reflector } from "@nestjs/core";
import { ExecutionContext, ForbiddenException } from "@nestjs/common";
import { PermissionsGuard } from "../common/guards/permissions.guard";
import { FeatureFlagGuard } from "../common/guards/feature-flag.guard";
import { PrismaService } from "../prisma/prisma.service";
import { RedisService } from "../common/redis/redis.service";
import { Role } from "@prisma/client";

describe("Phase 1 — RBAC & Security Hardening Tests", () => {
  let permissionsGuard: PermissionsGuard;
  let featureFlagGuard: FeatureFlagGuard;
  let reflector: Reflector;

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
    },
    featureFlag: {
      findUnique: jest.fn(),
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
        PermissionsGuard,
        FeatureFlagGuard,
        Reflector,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    permissionsGuard = module.get<PermissionsGuard>(PermissionsGuard);
    featureFlagGuard = module.get<FeatureFlagGuard>(FeatureFlagGuard);
    reflector = module.get<Reflector>(Reflector);
    jest.clearAllMocks();
  });

  const createMockContext = (user?: any) => {
    return {
      getHandler: () => ({}),
      getClass: () => ({}),
      switchToHttp: () => ({
        getRequest: () => ({ user }),
      }),
    } as unknown as ExecutionContext;
  };

  describe("PermissionsGuard", () => {
    it("should allow access if no @RequirePermissions decorator is defined", async () => {
      jest.spyOn(reflector, "getAllAndOverride").mockReturnValue(undefined);
      const context = createMockContext({ id: "user-1", role: Role.EMPLOYEE });

      const result = await permissionsGuard.canActivate(context);
      expect(result).toBe(true);
    });

    it("should allow SUPER_ADMIN to bypass all required permissions", async () => {
      jest
        .spyOn(reflector, "getAllAndOverride")
        .mockReturnValue(["payroll:finalize", "settings:manage"]);
      const context = createMockContext({
        id: "admin-1",
        role: Role.SUPER_ADMIN,
      });

      const result = await permissionsGuard.canActivate(context);
      expect(result).toBe(true);
    });

    it("should throw ForbiddenException if user has no authentication identity", async () => {
      jest
        .spyOn(reflector, "getAllAndOverride")
        .mockReturnValue(["employees:read"]);
      const context = createMockContext(null);

      await expect(permissionsGuard.canActivate(context)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it("should allow access when user has all required permissions (from Redis cache)", async () => {
      jest
        .spyOn(reflector, "getAllAndOverride")
        .mockReturnValue(["employees:read", "attendance:read"]);
      mockRedisService.get.mockResolvedValue(
        JSON.stringify(["employees:read", "attendance:read", "requests:read"]),
      );

      const context = createMockContext({ id: "user-1", role: Role.EMPLOYEE });
      const result = await permissionsGuard.canActivate(context);
      expect(result).toBe(true);
    });

    it("should deny access with 403 when user is missing any required permission", async () => {
      jest
        .spyOn(reflector, "getAllAndOverride")
        .mockReturnValue(["payroll:finalize"]);
      mockRedisService.get.mockResolvedValue(
        JSON.stringify(["employees:read", "attendance:read"]),
      );

      const context = createMockContext({ id: "user-1", role: Role.EMPLOYEE });
      await expect(permissionsGuard.canActivate(context)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it("should query database and cache resolved permissions when Redis cache misses", async () => {
      jest
        .spyOn(reflector, "getAllAndOverride")
        .mockReturnValue(["payroll:read"]);
      mockRedisService.get.mockResolvedValue(null);

      mockPrismaService.user.findUnique.mockResolvedValue({
        id: "user-hr",
        userRoles: [
          {
            role: {
              isActive: true,
              rolePermissions: [
                { permission: { slug: "payroll:read" } },
                { permission: { slug: "payroll:calculate" } },
              ],
            },
          },
        ],
      });

      const context = createMockContext({
        id: "user-hr",
        role: Role.HR_MANAGER,
      });
      const result = await permissionsGuard.canActivate(context);
      expect(result).toBe(true);
      expect(mockRedisService.set).toHaveBeenCalledWith(
        "user:permissions:user-hr",
        JSON.stringify(["payroll:read", "payroll:calculate"]),
        300,
      );
    });
  });

  describe("FeatureFlagGuard", () => {
    it("should allow access when no feature flag is required", async () => {
      jest.spyOn(reflector, "getAllAndOverride").mockReturnValue(undefined);
      const context = createMockContext();

      const result = await featureFlagGuard.canActivate(context);
      expect(result).toBe(true);
    });

    it("should allow access when required feature flag is enabled", async () => {
      jest
        .spyOn(reflector, "getAllAndOverride")
        .mockReturnValue("enable_reporting_hierarchy");
      mockRedisService.get.mockResolvedValue("true");

      const context = createMockContext();
      const result = await featureFlagGuard.canActivate(context);
      expect(result).toBe(true);
    });

    it("should throw ForbiddenException when feature flag is disabled", async () => {
      jest
        .spyOn(reflector, "getAllAndOverride")
        .mockReturnValue("enable_biometric_face_id");
      mockRedisService.get.mockResolvedValue("false");

      const context = createMockContext();
      await expect(featureFlagGuard.canActivate(context)).rejects.toThrow(
        ForbiddenException,
      );
    });
  });
});
