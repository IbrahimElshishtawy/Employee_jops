import { Test, TestingModule } from "@nestjs/testing";
import { InventoryService } from "./inventory.service";
import { InventoryRepository } from "./inventory.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { ConflictException, NotFoundException, BadRequestException } from "@nestjs/common";
import { StockMovementType } from "@prisma/client";

describe("InventoryService", () => {
  let service: InventoryService;
  let repo: jest.Mocked<InventoryRepository>;
  let prisma: any;

  beforeEach(async () => {
    const mockRepo = {
      generateMovementNumber: jest.fn().mockResolvedValue("SM-20260903-00001"),
      generateCountNumber: jest.fn().mockResolvedValue("SC-20260903-0001"),
      createWarehouse: jest.fn(),
      findWarehouses: jest.fn(),
      findWarehouseById: jest.fn(),
      findWarehouseByCode: jest.fn(),
      createStockCategory: jest.fn(),
      findStockCategories: jest.fn(),
      findStockCategoryById: jest.fn(),
      createStockItem: jest.fn(),
      findStockItemById: jest.fn(),
      findStockItemBySku: jest.fn(),
      findStockItems: jest.fn(),
      updateStockItem: jest.fn(),
      executeStockMovement: jest.fn(),
      findMovements: jest.fn(),
      createStockCount: jest.fn(),
      findStockCounts: jest.fn(),
    };

    const mockPrisma = {
      department: { findUnique: jest.fn() },
      stockCategory: { findUnique: jest.fn() },
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const mockNotifications = {
      sendInAppNotification: jest.fn().mockResolvedValue({ id: "notif-1" }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        InventoryService,
        { provide: InventoryRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: NotificationsService, useValue: mockNotifications },
      ],
    }).compile();

    service = module.get<InventoryService>(InventoryService);
    repo = module.get(InventoryRepository);
    prisma = module.get(PrismaService);
  });

  describe("createWarehouse", () => {
    it("should throw ConflictException if warehouse code exists", async () => {
      repo.findWarehouseByCode.mockResolvedValue({ id: "wh-1" } as any);

      await expect(
        service.createWarehouse("user-1", { code: "WH-MAIN", name: "Main Store" }),
      ).rejects.toThrow(ConflictException);
    });

    it("should create warehouse and log audit", async () => {
      repo.findWarehouseByCode.mockResolvedValue(null);
      repo.createWarehouse.mockResolvedValue({ id: "wh-1", code: "WH-MAIN", name: "Main Store" } as any);

      const result = await service.createWarehouse("user-1", { code: "WH-MAIN", name: "Main Store" });
      expect(result.id).toBe("wh-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("createStockItem", () => {
    it("should throw ConflictException if SKU exists", async () => {
      repo.findStockItemBySku.mockResolvedValue({ id: "item-1" } as any);

      await expect(
        service.createStockItem("user-1", {
          sku: "SKU-01",
          name: "Item",
          categoryId: "cat-1",
          warehouseId: "wh-1",
        }),
      ).rejects.toThrow(ConflictException);
    });

    it("should create stock item successfully", async () => {
      repo.findStockItemBySku.mockResolvedValue(null);
      repo.findStockCategoryById.mockResolvedValue({ id: "cat-1" } as any);
      repo.findWarehouseById.mockResolvedValue({ id: "wh-1" } as any);
      repo.createStockItem.mockResolvedValue({
        id: "item-1",
        sku: "SKU-01",
        name: "Item",
        warehouseId: "wh-1",
      } as any);

      const result = await service.createStockItem("user-1", {
        sku: "SKU-01",
        name: "Item",
        categoryId: "cat-1",
        warehouseId: "wh-1",
      });

      expect(result.id).toBe("item-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("executeStockMovement", () => {
    it("should throw BadRequestException on ISSUE if stock is insufficient", async () => {
      repo.findStockItemById.mockResolvedValue({
        id: "item-1",
        sku: "SKU-01",
        name: "Towel",
        quantityOnHand: 3,
      } as any);
      repo.findWarehouseById.mockResolvedValue({ id: "wh-1" } as any);

      await expect(
        service.executeStockMovement("user-1", {
          itemId: "item-1",
          warehouseId: "wh-1",
          type: StockMovementType.ISSUE,
          quantity: 10,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should execute stock movement and update balance", async () => {
      repo.findStockItemById.mockResolvedValue({
        id: "item-1",
        sku: "SKU-01",
        name: "Towel",
        quantityOnHand: 20,
      } as any);
      repo.findWarehouseById.mockResolvedValue({ id: "wh-1" } as any);
      repo.executeStockMovement.mockResolvedValue({
        movement: { id: "sm-1" },
        updatedItem: { quantityOnHand: 15, reorderLevel: 10 },
      } as any);

      const result = await service.executeStockMovement("user-1", {
        itemId: "item-1",
        warehouseId: "wh-1",
        type: StockMovementType.ISSUE,
        quantity: 5,
      });

      expect(result.movement.id).toBe("sm-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
