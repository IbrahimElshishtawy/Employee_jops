import { Test, TestingModule } from "@nestjs/testing";
import { PermissionsService } from "./permissions.service";
import { PrismaService } from "../../prisma/prisma.service";
import { ConflictException, NotFoundException } from "@nestjs/common";
import { PermissionAction, PermissionSubject } from "@prisma/client";

describe("PermissionsService", () => {
  let service: PermissionsService;

  const mockPrismaService = {
    permission: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PermissionsService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<PermissionsService>(PermissionsService);
    jest.clearAllMocks();
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  describe("create", () => {
    it("should create a permission successfully", async () => {
      mockPrismaService.permission.findUnique.mockResolvedValue(null);
      mockPrismaService.permission.create.mockResolvedValue({
        id: "perm-1",
        slug: "employees:read",
        action: PermissionAction.READ,
        subject: PermissionSubject.EMPLOYEES,
        module: "employees",
      });
      mockPrismaService.auditLog.create.mockResolvedValue({});

      const result = await service.create(
        {
          slug: "employees:read",
          action: PermissionAction.READ,
          subject: PermissionSubject.EMPLOYEES,
          module: "employees",
        },
        "admin-user-id",
      );

      expect(result.slug).toBe("employees:read");
      expect(mockPrismaService.permission.create).toHaveBeenCalled();
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });

    it("should throw ConflictException if slug already exists", async () => {
      mockPrismaService.permission.findUnique.mockResolvedValue({
        id: "perm-1",
        slug: "employees:read",
      });

      await expect(
        service.create({
          slug: "employees:read",
          action: PermissionAction.READ,
          subject: PermissionSubject.EMPLOYEES,
          module: "employees",
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe("findOne", () => {
    it("should find permission by id or slug", async () => {
      mockPrismaService.permission.findFirst.mockResolvedValue({
        id: "perm-1",
        slug: "employees:read",
      });

      const res = await service.findOne("employees:read");
      expect(res.id).toBe("perm-1");
    });

    it("should throw NotFoundException if permission not found", async () => {
      mockPrismaService.permission.findFirst.mockResolvedValue(null);

      await expect(service.findOne("non-existent")).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe("getGroupedByModule", () => {
    it("should return permissions grouped by module", async () => {
      mockPrismaService.permission.findMany.mockResolvedValue([
        { id: "1", slug: "emp:read", module: "employees" },
        { id: "2", slug: "emp:create", module: "employees" },
        { id: "3", slug: "att:read", module: "attendance" },
      ]);

      const grouped = await service.getGroupedByModule();
      expect(grouped.employees).toHaveLength(2);
      expect(grouped.attendance).toHaveLength(1);
    });
  });
});
