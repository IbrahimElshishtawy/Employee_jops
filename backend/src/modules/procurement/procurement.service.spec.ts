import { Test, TestingModule } from "@nestjs/testing";
import { ProcurementService } from "./procurement.service";
import { ProcurementRepository } from "./procurement.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { ConflictException, NotFoundException, BadRequestException } from "@nestjs/common";
import { UserStatus, PurchaseRequestStatus, PurchaseOrderStatus } from "@prisma/client";

describe("ProcurementService", () => {
  let service: ProcurementService;
  let repo: jest.Mocked<ProcurementRepository>;
  let prisma: any;
  let notifications: jest.Mocked<NotificationsService>;

  beforeEach(async () => {
    const mockRepo = {
      generatePRNumber: jest.fn().mockResolvedValue("PR-20260903-0001"),
      generatePONumber: jest.fn().mockResolvedValue("PO-20260903-0001"),
      createSupplier: jest.fn(),
      findSuppliers: jest.fn(),
      findSupplierById: jest.fn(),
      findSupplierByCode: jest.fn(),
      updateSupplier: jest.fn(),
      createPurchaseRequest: jest.fn(),
      findPurchaseRequests: jest.fn(),
      findPurchaseRequestById: jest.fn(),
      updatePurchaseRequestStatus: jest.fn(),
      createPurchaseOrder: jest.fn(),
      findPurchaseOrders: jest.fn(),
      findPurchaseOrderById: jest.fn(),
      updatePurchaseOrderStatus: jest.fn(),
      createSupplierInvoice: jest.fn(),
      findSupplierInvoices: jest.fn(),
      findSupplierInvoiceById: jest.fn(),
    };

    const mockPrisma = {
      employeeProfile: { findUnique: jest.fn() },
      department: { findUnique: jest.fn() },
      supplierInvoice: { findUnique: jest.fn() },
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const mockNotifications = {
      sendNotification: jest.fn().mockResolvedValue({ id: "notif-1" }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProcurementService,
        { provide: ProcurementRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: NotificationsService, useValue: mockNotifications },
      ],
    }).compile();

    service = module.get<ProcurementService>(ProcurementService);
    repo = module.get(ProcurementRepository);
    prisma = module.get(PrismaService);
    notifications = module.get(NotificationsService);
  });

  describe("createSupplier", () => {
    it("should throw ConflictException if supplier code exists", async () => {
      repo.findSupplierByCode.mockResolvedValue({ id: "sup-1" } as any);

      await expect(
        service.createSupplier("user-1", { code: "SUP-01", name: "Al-Safwa" }),
      ).rejects.toThrow(ConflictException);
    });

    it("should create supplier and log audit", async () => {
      repo.findSupplierByCode.mockResolvedValue(null);
      repo.createSupplier.mockResolvedValue({ id: "sup-1", code: "SUP-01", name: "Al-Safwa" } as any);

      const result = await service.createSupplier("user-1", { code: "SUP-01", name: "Al-Safwa" });
      expect(result.id).toBe("sup-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("createPurchaseRequest", () => {
    it("should throw BadRequestException if requester is inactive or missing", async () => {
      prisma.employeeProfile.findUnique.mockResolvedValue(null);

      await expect(
        service.createPurchaseRequest("user-1", {
          departmentId: "dept-1",
          items: [{ itemName: "Towel", quantity: 5, estimatedUnitPrice: 10 }],
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should create purchase request with calculated total cost", async () => {
      prisma.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
        user: { status: UserStatus.ACTIVE },
      });
      prisma.department.findUnique.mockResolvedValue({ id: "dept-1" });
      repo.createPurchaseRequest.mockResolvedValue({
        id: "pr-1",
        requestNumber: "PR-20260903-0001",
        totalEstimatedCost: 50,
      } as any);

      const result = await service.createPurchaseRequest("user-1", {
        departmentId: "dept-1",
        items: [{ itemName: "Towel", quantity: 5, estimatedUnitPrice: 10 }],
      });

      expect(result.id).toBe("pr-1");
      expect(repo.createPurchaseRequest).toHaveBeenCalledWith(
        "emp-1",
        expect.anything(),
        "PR-20260903-0001",
        50,
      );
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("createPurchaseOrder", () => {
    it("should create PO and mark linked PR as ORDERED", async () => {
      repo.findSupplierById.mockResolvedValue({ id: "sup-1" } as any);
      repo.findPurchaseRequestById.mockResolvedValue({ id: "pr-1" } as any);
      repo.createPurchaseOrder.mockResolvedValue({
        id: "po-1",
        orderNumber: "PO-20260903-0001",
        totalAmount: 115,
      } as any);

      const result = await service.createPurchaseOrder("user-1", {
        purchaseRequestId: "pr-1",
        supplierId: "sup-1",
        taxAmount: 15,
        items: [{ itemName: "Towel", quantityOrdered: 10, unitPrice: 10 }],
      });

      expect(result.id).toBe("po-1");
      expect(repo.updatePurchaseRequestStatus).toHaveBeenCalledWith(
        "pr-1",
        PurchaseRequestStatus.ORDERED,
      );
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
