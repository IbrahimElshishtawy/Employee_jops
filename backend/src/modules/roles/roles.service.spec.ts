import { Test, TestingModule } from "@nestjs/testing";
import { RolesService } from "./roles.service";
import { PrismaService } from "../../prisma/prisma.service";
import { RedisService } from "../../common/redis/redis.service";
import {
  ConflictException,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";

describe("RolesService", () => {
  let service: RolesService;
  let prisma: PrismaService;
  let redis: RedisService;

  const mockPrismaService = {
    roleRecord: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    permission: {
      findMany: jest.fn(),
    },
    user: {
      findUnique: jest.fn(),
    },
    userRole: {
      findMany: jest.fn(),
      deleteMany: jest.fn(),
      createMany: jest.fn(),
    },
    rolePermission: {
      deleteMany: jest.fn(),
      createMany: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
    $transaction: jest.fn().mockImplementation(async (callback) => {
      return callback(mockPrismaService);
    }),
  };

  const mockRedisService = {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RolesService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    service = module.get<RolesService>(RolesService);
    prisma = module.get<PrismaService>(PrismaService);
    redis = module.get<RedisService>(RedisService);
    jest.clearAllMocks();
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  describe("create", () => {
    it("should create a custom role successfully", async () => {
      mockPrismaService.roleRecord.findUnique.mockResolvedValue(null);
      mockPrismaService.permission.findMany.mockResolvedValue([
        { id: "perm-1", slug: "payroll:read" },
      ]);
      mockPrismaService.roleRecord.create.mockResolvedValue({
        id: "role-1",
        name: "Payroll Officer",
        slug: "payroll-officer",
        isSystem: false,
        rolePermissions: [
          { permission: { id: "perm-1", slug: "payroll:read" } },
        ],
      });
      mockPrismaService.auditLog.create.mockResolvedValue({});

      const result = await service.create(
        {
          name: "Payroll Officer",
          slug: "payroll-officer",
          permissionSlugs: ["payroll:read"],
        },
        "admin-id",
      );

      expect(result.slug).toBe("payroll-officer");
      expect(mockPrismaService.roleRecord.create).toHaveBeenCalled();
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });

    it("should throw ConflictException if slug already exists", async () => {
      mockPrismaService.roleRecord.findUnique.mockResolvedValue({
        id: "role-1",
        slug: "payroll-officer",
      });

      await expect(
        service.create({
          name: "Payroll Officer",
          slug: "payroll-officer",
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe("remove", () => {
    it("should throw BadRequestException when attempting to delete a system role", async () => {
      mockPrismaService.roleRecord.findFirst.mockResolvedValue({
        id: "role-sys",
        name: "Super Admin",
        slug: "super-admin",
        isSystem: true,
        userRoles: [],
      });

      await expect(service.remove("super-admin")).rejects.toThrow(
        BadRequestException,
      );
    });

    it("should delete custom role and invalidate cache", async () => {
      mockPrismaService.roleRecord.findFirst.mockResolvedValue({
        id: "role-custom",
        name: "Custom Role",
        slug: "custom-role",
        isSystem: false,
        userRoles: [{ userId: "user-1" }],
      });
      mockPrismaService.roleRecord.delete.mockResolvedValue({});
      mockPrismaService.auditLog.create.mockResolvedValue({});

      const res = await service.remove("role-custom", "admin-id");
      expect(res.message).toContain("deleted successfully");
      expect(mockRedisService.del).toHaveBeenCalledWith(
        "user:permissions:user-1",
      );
    });
  });

  describe("syncRolePermissions", () => {
    it("should sync permissions and invalidate redis cache", async () => {
      mockPrismaService.roleRecord.findFirst.mockResolvedValue({
        id: "role-1",
        slug: "payroll-officer",
        rolePermissions: [],
        userRoles: [],
      });
      mockPrismaService.permission.findMany.mockResolvedValue([
        { id: "perm-1", slug: "payroll:calculate" },
      ]);
      mockPrismaService.userRole.findMany.mockResolvedValue([
        { userId: "user-123" },
      ]);
      mockPrismaService.auditLog.create.mockResolvedValue({});

      await service.syncRolePermissions(
        "role-1",
        { permissionSlugs: ["payroll:calculate"] },
        "admin-id",
      );

      expect(mockRedisService.del).toHaveBeenCalledWith(
        "user:permissions:user-123",
      );
    });
  });

  describe("assignRolesToUser", () => {
    it("should assign roles to user and invalidate cache", async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: "user-1",
        email: "test@example.com",
      });
      mockPrismaService.roleRecord.findMany.mockResolvedValue([
        { id: "role-1", slug: "hr-manager" },
      ]);
      mockPrismaService.userRole.deleteMany.mockResolvedValue({});
      mockPrismaService.userRole.createMany.mockResolvedValue({});
      mockPrismaService.auditLog.create.mockResolvedValue({});

      // Mock return for getUserRolesAndPermissions
      mockPrismaService.user.findUnique
        .mockResolvedValueOnce({
          id: "user-1",
          email: "test@example.com",
        })
        .mockResolvedValueOnce({
          id: "user-1",
          email: "test@example.com",
          role: "EMPLOYEE",
          userRoles: [
            {
              role: {
                id: "role-1",
                name: "HR Manager",
                slug: "hr-manager",
                isActive: true,
                rolePermissions: [{ permission: { slug: "employees:read" } }],
              },
            },
          ],
        });

      const res = await service.assignRolesToUser(
        { userId: "user-1", roleSlugs: ["hr-manager"] },
        "admin-id",
      );

      expect(mockRedisService.del).toHaveBeenCalledWith(
        "user:permissions:user-1",
      );
      expect(res.roles).toHaveLength(1);
    });
  });
});
