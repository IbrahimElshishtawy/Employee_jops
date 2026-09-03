import { Test, TestingModule } from "@nestjs/testing";
import { PerformanceService } from "./performance.service";
import { PerformanceRepository } from "./performance.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { ConflictException, NotFoundException } from "@nestjs/common";
import { GoalStatus, ReviewStatus, UserStatus } from "@prisma/client";

describe("PerformanceService", () => {
  let service: PerformanceService;
  let repo: jest.Mocked<PerformanceRepository>;
  let prisma: any;
  let notifications: jest.Mocked<NotificationsService>;

  beforeEach(async () => {
    const mockRepo = {
      generateReviewNumber: jest.fn().mockResolvedValue("PRV-20260903-0001"),
      createKPI: jest.fn(),
      findKPIs: jest.fn(),
      findKPIById: jest.fn(),
      findKPIByCode: jest.fn(),
      createGoal: jest.fn(),
      findGoals: jest.fn(),
      findGoalById: jest.fn(),
      updateGoalProgress: jest.fn(),
      createReview: jest.fn(),
      findReviews: jest.fn(),
      findReviewById: jest.fn(),
      acknowledgeReview: jest.fn(),
    };

    const mockPrisma = {
      employeeProfile: { findUnique: jest.fn() },
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const mockNotifications = {
      sendNotification: jest.fn().mockResolvedValue({ id: "notif-1" }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PerformanceService,
        { provide: PerformanceRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: NotificationsService, useValue: mockNotifications },
      ],
    }).compile();

    service = module.get<PerformanceService>(PerformanceService);
    repo = module.get(PerformanceRepository);
    prisma = module.get(PrismaService);
    notifications = module.get(NotificationsService);
  });

  describe("createKPI", () => {
    it("should throw ConflictException if KPI code exists", async () => {
      repo.findKPIByCode.mockResolvedValue({ id: "kpi-1" } as any);

      await expect(
        service.createKPI("user-1", {
          code: "KPI-01",
          title: "Satisfaction",
          targetValue: 90,
        }),
      ).rejects.toThrow(ConflictException);
    });

    it("should create KPI and log audit", async () => {
      repo.findKPIByCode.mockResolvedValue(null);
      repo.createKPI.mockResolvedValue({
        id: "kpi-1",
        code: "KPI-01",
        title: "Satisfaction",
      } as any);

      const result = await service.createKPI("user-1", {
        code: "KPI-01",
        title: "Satisfaction",
        targetValue: 90,
      });

      expect(result.id).toBe("kpi-1");
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("updateGoalProgress", () => {
    it("should automatically set status to ACHIEVED when target is reached", async () => {
      repo.findGoalById.mockResolvedValue({
        id: "goal-1",
        targetValue: 100,
        currentValue: 50,
        status: GoalStatus.IN_PROGRESS,
      } as any);
      repo.updateGoalProgress.mockResolvedValue({
        id: "goal-1",
        currentValue: 100,
        status: GoalStatus.ACHIEVED,
      } as any);

      const result = await service.updateGoalProgress("goal-1", "user-1", {
        currentValue: 100,
      });
      expect(repo.updateGoalProgress).toHaveBeenCalledWith(
        "goal-1",
        expect.objectContaining({
          status: GoalStatus.ACHIEVED,
        }),
      );
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("createReview", () => {
    it("should create review, notify employee, and log audit", async () => {
      prisma.employeeProfile.findUnique
        .mockResolvedValueOnce({
          id: "rev-1",
          user: { status: UserStatus.ACTIVE },
        }) // Reviewer
        .mockResolvedValueOnce({ id: "emp-1", user: { id: "user-emp-1" } }); // Employee

      repo.createReview.mockResolvedValue({
        id: "review-1",
        reviewNumber: "PRV-20260903-0001",
        overallRating: 4.5,
      } as any);

      const result = await service.createReview("user-1", {
        employeeId: "emp-1",
        cycleName: "Annual 2026",
        periodStart: "2026-01-01",
        periodEnd: "2026-12-31",
        overallRating: 4.5,
      });

      expect(result.id).toBe("review-1");
      expect(notifications.sendNotification).toHaveBeenCalled();
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
