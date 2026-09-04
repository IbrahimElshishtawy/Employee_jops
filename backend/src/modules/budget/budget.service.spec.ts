import { Test, TestingModule } from "@nestjs/testing";
import { BudgetService } from "./budget.service";
import { BudgetRepository } from "./budget.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { ConflictException, NotFoundException } from "@nestjs/common";

describe("BudgetService", () => {
  let service: BudgetService;
  let repo: jest.Mocked<BudgetRepository>;
  let prisma: any;
  let notifications: jest.Mocked<NotificationsService>;

  beforeEach(async () => {
    const mockRepo = {
      createBudget: jest.fn(),
      findBudgets: jest.fn(),
      findBudgetById: jest.fn(),
      findBudgetByCode: jest.fn(),
      updateBudgetStatus: jest.fn(),
      findBudgetLineById: jest.fn(),
      recordSpending: jest.fn(),
    };

    const mockPrisma = {
      department: { findUnique: jest.fn() },
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const mockNotifications = {
      sendNotification: jest.fn().mockResolvedValue({ id: "notif-1" }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BudgetService,
        { provide: BudgetRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: NotificationsService, useValue: mockNotifications },
      ],
    }).compile();

    service = module.get<BudgetService>(BudgetService);
    repo = module.get(BudgetRepository);
    prisma = module.get(PrismaService);
    notifications = module.get(NotificationsService);
    expect(notifications).toBeDefined();
  });

  describe("createBudget", () => {
    it("should throw ConflictException if budget code exists", async () => {
      repo.findBudgetByCode.mockResolvedValue({ id: "bud-1" } as any);

      await expect(
        service.createBudget("user-1", {
          budgetCode: "BUD-2026",
          title: "Budget 2026",
          fiscalYear: 2026,
          startDate: "2026-01-01",
          endDate: "2026-12-31",
          lines: [{ category: "SUPPLIES", allocatedAmount: 50000 }],
        }),
      ).rejects.toThrow(ConflictException);
    });

    it("should create budget and calculate totalAllocated", async () => {
      repo.findBudgetByCode.mockResolvedValue(null);
      repo.createBudget.mockResolvedValue({
        id: "bud-1",
        budgetCode: "BUD-2026",
        totalAllocated: 50000,
        fiscalYear: 2026,
      } as any);

      const result = await service.createBudget("user-1", {
        budgetCode: "BUD-2026",
        title: "Budget 2026",
        fiscalYear: 2026,
        startDate: "2026-01-01",
        endDate: "2026-12-31",
        lines: [{ category: "SUPPLIES", allocatedAmount: 50000 }],
      });

      expect(result.id).toBe("bud-1");
      expect(repo.createBudget).toHaveBeenCalledWith(expect.anything(), 50000);
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("recordSpending", () => {
    it("should throw NotFoundException if budget line is not found", async () => {
      repo.findBudgetLineById.mockResolvedValue(null);

      await expect(
        service.recordSpending("user-1", {
          budgetLineId: "line-1",
          amount: 1000,
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it("should record spending successfully", async () => {
      repo.findBudgetLineById.mockResolvedValue({
        id: "line-1",
        budgetId: "bud-1",
        category: "SUPPLIES",
        allocatedAmount: 10000,
        spentAmount: 2000,
        budget: { budgetCode: "BUD-2026" },
      } as any);
      repo.recordSpending.mockResolvedValue({
        updatedBudget: { id: "bud-1", totalSpent: 3000 },
        updatedLine: { id: "line-1", spentAmount: 3000 },
      } as any);

      const result = await service.recordSpending("user-1", {
        budgetLineId: "line-1",
        amount: 1000,
      });

      expect(result.updatedLine.spentAmount).toBe(3000);
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
