import { Test, TestingModule } from "@nestjs/testing";
import { OnboardingService } from "./onboarding.service";
import { PrismaService } from "../../prisma/prisma.service";
import { ConflictException } from "@nestjs/common";
import { OnboardingStatus } from "@prisma/client";

describe("OnboardingService", () => {
  let service: OnboardingService;

  const mockPrismaService = {
    onboardingWorkflow: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    onboardingTask: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      delete: jest.fn(),
    },
    employeeProfile: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    auditLog: {
      create: jest.fn().mockResolvedValue({ id: "audit-1" }),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OnboardingService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<OnboardingService>(OnboardingService);
    jest.clearAllMocks();
  });

  describe("createWorkflow", () => {
    it("should initialize workflow with default tasks", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
        onboardingWorkflow: null,
      });
      mockPrismaService.onboardingWorkflow.create.mockResolvedValue({
        id: "wf-1",
        employeeId: "emp-1",
        status: OnboardingStatus.PENDING,
        tasks: [{ id: "t-1", title: "Sign Contract" }],
      });

      const result = await service.createWorkflow(
        { employeeId: "emp-1" },
        "admin-1",
      );

      expect(result.id).toBe("wf-1");
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });

    it("should throw ConflictException if workflow already exists", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: "emp-1",
        onboardingWorkflow: { id: "wf-1" },
      });

      await expect(
        service.createWorkflow({ employeeId: "emp-1" }, "admin-1"),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe("completeTask & Progress Calculation", () => {
    it("should mark task as completed and recalculate workflow percentage", async () => {
      mockPrismaService.onboardingTask.findUnique.mockResolvedValue({
        id: "task-1",
        workflowId: "wf-1",
        title: "Submit National ID Copy",
      });
      mockPrismaService.onboardingTask.update.mockResolvedValue({
        id: "task-1",
        isCompleted: true,
        completedAt: new Date(),
      });
      mockPrismaService.onboardingTask.findMany.mockResolvedValue([
        { id: "task-1", isCompleted: true, isMandatory: true },
        { id: "task-2", isCompleted: false, isMandatory: true },
      ]);
      mockPrismaService.onboardingWorkflow.update.mockResolvedValue({
        id: "wf-1",
        progressPercentage: 50,
        status: OnboardingStatus.IN_PROGRESS,
      });

      const result = await service.completeTask(
        "task-1",
        { isCompleted: true, notes: "ID checked" },
        "user-1",
      );

      expect(result.task.isCompleted).toBe(true);
      expect(result.workflow.progressPercentage).toBe(50);
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });

    it("should auto-complete workflow and update EmployeeProfile when all tasks done", async () => {
      mockPrismaService.onboardingTask.findUnique.mockResolvedValue({
        id: "task-1",
        workflowId: "wf-1",
        title: "Task 1",
      });
      mockPrismaService.onboardingTask.update.mockResolvedValue({
        id: "task-1",
        isCompleted: true,
      });
      mockPrismaService.onboardingTask.findMany.mockResolvedValue([
        { id: "task-1", isCompleted: true, isMandatory: true },
      ]);
      mockPrismaService.onboardingWorkflow.update.mockResolvedValue({
        id: "wf-1",
        employeeId: "emp-1",
        progressPercentage: 100,
        status: OnboardingStatus.COMPLETED,
      });

      const result = await service.completeTask(
        "task-1",
        { isCompleted: true },
        "user-1",
      );

      expect(result.workflow.status).toBe(OnboardingStatus.COMPLETED);
      expect(mockPrismaService.employeeProfile.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: "emp-1" },
          data: expect.objectContaining({ isProfileComplete: true }),
        }),
      );
    });
  });

  describe("finalizeWorkflow", () => {
    it("should complete all tasks, set workflow to COMPLETED, and unlock employee profile", async () => {
      mockPrismaService.onboardingWorkflow.findUnique.mockResolvedValue({
        id: "wf-1",
        employeeId: "emp-1",
        tasks: [{ id: "t-1" }],
      });
      mockPrismaService.onboardingTask.updateMany.mockResolvedValue({
        count: 1,
      });
      mockPrismaService.onboardingWorkflow.update.mockResolvedValue({
        id: "wf-1",
        status: OnboardingStatus.COMPLETED,
        progressPercentage: 100,
      });

      const result = await service.finalizeWorkflow("wf-1", "admin-1");

      expect(result.status).toBe(OnboardingStatus.COMPLETED);
      expect(mockPrismaService.employeeProfile.update).toHaveBeenCalled();
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });
  });
});
