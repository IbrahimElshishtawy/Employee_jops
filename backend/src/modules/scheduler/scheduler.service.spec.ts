import { Test, TestingModule } from "@nestjs/testing";
import { SchedulerService } from "./scheduler.service";
import { DistributedLockService } from "./distributed-lock.service";
import { OfflineSyncService } from "../offline-sync/offline-sync.service";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { TaskStatus, SyncStatus } from "@prisma/client";

describe("SchedulerService", () => {
  let service: SchedulerService;
  let prisma: any;
  let notifications: any;
  let lockService: any;
  let offlineSync: any;

  beforeEach(async () => {
    prisma = {
      task: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: "task-1",
            title: "Urgent Maintenance",
            assignee: { userId: "user-1" },
          },
        ]),
        update: jest
          .fn()
          .mockResolvedValue({ id: "task-1", status: TaskStatus.OVERDUE }),
      },
      userDeviceSession: {
        deleteMany: jest.fn().mockResolvedValue({ count: 5 }),
      },
      offlineSyncQueue: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: "sync-1",
            userId: "user-1",
            entityType: "Task",
            action: "UPDATE",
            payload: {},
            clientTimestamp: new Date(),
          },
        ]),
        update: jest.fn().mockResolvedValue({ id: "sync-1" }),
      },
      attendanceRecord: {
        findMany: jest.fn().mockResolvedValue([]),
      },
    };

    notifications = {
      sendNotification: jest.fn().mockResolvedValue({ id: "notif-1" }),
    };

    lockService = {
      withLock: jest.fn().mockImplementation(async (_key, _ttl, fn) => {
        const result = await fn();
        return { executed: true, result };
      }),
    };

    offlineSync = {
      applyEntityOperation: jest.fn().mockResolvedValue({
        status: SyncStatus.PROCESSED,
        failureReason: null,
        appliedData: { success: true },
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SchedulerService,
        { provide: PrismaService, useValue: prisma },
        { provide: NotificationsService, useValue: notifications },
        { provide: DistributedLockService, useValue: lockService },
        { provide: OfflineSyncService, useValue: offlineSync },
      ],
    }).compile();

    service = module.get<SchedulerService>(SchedulerService);
  });

  it("should list registered jobs", async () => {
    const jobs = await service.listJobs();
    expect(jobs.length).toBe(6);
    expect(jobs.some((j) => j.name === "task-overdue-checker")).toBe(true);
    expect(jobs.some((j) => j.name === "session-cleanup")).toBe(true);
    expect(jobs.some((j) => j.name === "backup-retention-cleanup")).toBe(true);
    expect(jobs.some((j) => j.name === "inventory-low-stock-alert")).toBe(true);
  });

  it("should execute task overdue checker successfully", async () => {
    const result = await service.executeJob("task-overdue-checker");
    expect(result.status).toBe("SUCCESS");
    expect(prisma.task.update).toHaveBeenCalled();
    expect(notifications.sendNotification).toHaveBeenCalled();
  });

  it("should execute session cleanup successfully", async () => {
    const result = await service.executeJob("session-cleanup");
    expect(result.status).toBe("SUCCESS");
    expect(prisma.userDeviceSession.deleteMany).toHaveBeenCalled();
  });

  it("should skip execution when locked by another instance in multi-instance cluster", async () => {
    lockService.withLock.mockResolvedValue({
      executed: false,
      skippedReason: "LOCKED_BY_ANOTHER_INSTANCE",
    });

    const result = await service.executeJob("task-overdue-checker");
    expect(result.status).toBe("SKIPPED");
    expect(result.reason).toBe("LOCKED_BY_ANOTHER_INSTANCE");
  });

  it("should execute offline sync retries through real offlineSyncService", async () => {
    const result = await service.processPendingSyncQueue();
    expect(result.processed).toBe(1);
    expect(offlineSync.applyEntityOperation).toHaveBeenCalled();
    expect(prisma.offlineSyncQueue.update).toHaveBeenCalled();
  });
});
