import { Test, TestingModule } from "@nestjs/testing";
import { MaintenanceService } from "./maintenance.service";
import { MaintenanceRepository } from "./maintenance.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { BadRequestException, NotFoundException, ConflictException } from "@nestjs/common";
import { UserStatus, MaintenanceRequestStatus, WorkOrderStatus } from "@prisma/client";

describe("MaintenanceService", () => {
  let service: MaintenanceService;
  let repo: jest.Mocked<MaintenanceRepository>;
  let prisma: any;
  let notifications: jest.Mocked<NotificationsService>;

  beforeEach(async () => {
    const mockRepo = {
      generateRequestNumber: jest.fn().mockResolvedValue("MR-20260903-0001"),
      generateOrderNumber: jest.fn().mockResolvedValue("WO-20260903-0001"),
      createRequest: jest.fn(),
      findRequestById: jest.fn(),
      findRequests: jest.fn(),
      updateRequest: jest.fn(),
      createWorkOrder: jest.fn(),
      findWorkOrderById: jest.fn(),
      findWorkOrders: jest.fn(),
      updateWorkOrder: jest.fn(),
      createSparePart: jest.fn(),
      findSpareParts: jest.fn(),
      findSparePartById: jest.fn(),
      findSparePartByNumber: jest.fn(),
      consumeSparePart: jest.fn(),
    };

    const mockPrisma = {
      employeeProfile: {
        findUnique: jest.fn(),
      },
      asset: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      department: {
        findUnique: jest.fn(),
      },
      auditLog: {
        create: jest.fn().mockResolvedValue({ id: "audit-1" }),
      },
    };

    const mockNotifications = {
      sendNotification: jest.fn().mockResolvedValue({ id: "notif-1" }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MaintenanceService,
        { provide: MaintenanceRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: NotificationsService, useValue: mockNotifications },
      ],
    }).compile();

    service = module.get<MaintenanceService>(MaintenanceService);
    repo = module.get(MaintenanceRepository);
    prisma = module.get(PrismaService);
    notifications = module.get(NotificationsService);
  });

  describe("createRequest", () => {
    it("should throw BadRequestException if requester profile is missing or inactive", async () => {
      prisma.employeeProfile.findUnique.mockResolvedValue(null);

      await expect(
        service.createRequest("user-1", {
          title: "Fix Door",
          description: "Broken hinge",
          departmentId: "dept-1",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should create request and set asset status to UNDER_MAINTENANCE", async () => {
      prisma.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
        user: { status: UserStatus.ACTIVE },
      });
      prisma.asset.findUnique.mockResolvedValue({ id: "ast-1" });
      prisma.department.findUnique.mockResolvedValue({ id: "dept-1", isActive: true });
      repo.createRequest.mockResolvedValue({
        id: "maint-1",
        requestNumber: "MR-20260903-0001",
        title: "Fix HVAC",
        priority: "HIGH",
      } as any);

      const result = await service.createRequest("user-1", {
        title: "Fix HVAC",
        description: "Not cooling",
        assetId: "ast-1",
        departmentId: "dept-1",
      });

      expect(result.id).toBe("maint-1");
      expect(prisma.asset.update).toHaveBeenCalled();
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("consumeSparePart", () => {
    it("should throw BadRequestException if stock is insufficient", async () => {
      repo.findWorkOrderById.mockResolvedValue({ id: "wo-1" } as any);
      repo.findSparePartById.mockResolvedValue({
        id: "part-1",
        name: "Filter",
        quantityOnHand: 1,
        unitCost: 50,
      } as any);

      await expect(
        service.consumeSparePart("wo-1", "user-1", {
          sparePartId: "part-1",
          quantity: 5,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should consume spare part and log audit if stock is sufficient", async () => {
      repo.findWorkOrderById.mockResolvedValue({ id: "wo-1" } as any);
      repo.findSparePartById.mockResolvedValue({
        id: "part-1",
        name: "Filter",
        quantityOnHand: 10,
        unitCost: 50,
      } as any);
      repo.consumeSparePart.mockResolvedValue({
        record: { id: "wosp-1" },
        updatedPart: { quantityOnHand: 8 },
      } as any);

      const result = await service.consumeSparePart("wo-1", "user-1", {
        sparePartId: "part-1",
        quantity: 2,
      });

      expect(result.record.id).toBe("wosp-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
