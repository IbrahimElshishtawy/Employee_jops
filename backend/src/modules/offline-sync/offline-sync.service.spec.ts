import { Test, TestingModule } from "@nestjs/testing";
import { OfflineSyncService } from "./offline-sync.service";
import { OfflineSyncRepository } from "./offline-sync.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { ConflictResolutionStrategy } from "./dto";
import { SyncStatus } from "@prisma/client";

describe("OfflineSyncService", () => {
  let service: OfflineSyncService;
  let repo: any;
  let prisma: any;

  beforeEach(async () => {
    repo = {
      enqueueBatch: jest.fn(),
      findExistingAction: jest.fn().mockResolvedValue(null),
      createQueueItem: jest.fn().mockImplementation((_userId, data) =>
        Promise.resolve({
          id: "queue-1",
          entityType: data.entityType,
          action: data.action,
          status: data.status,
          failureReason: data.failureReason,
          payload: data.payload,
        }),
      ),
      findQueue: jest.fn(),
      findItemById: jest.fn(),
      updateItemStatus: jest.fn(),
      findLogs: jest.fn(),
    };

    prisma = {
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
      task: {
        findUnique: jest.fn(),
        update: jest.fn().mockResolvedValue({ id: "t-1", status: "COMPLETED" }),
        findMany: jest.fn().mockResolvedValue([]),
      },
      serviceRequest: {
        create: jest.fn().mockResolvedValue({ id: "sr-1" }),
      },
      employeeProfile: {
        findFirst: jest
          .fn()
          .mockResolvedValue({ id: "emp-1", departmentId: "dept-1" }),
      },
      notification: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      request: {
        findMany: jest.fn().mockResolvedValue([]),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OfflineSyncService,
        { provide: OfflineSyncRepository, useValue: repo },
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = module.get<OfflineSyncService>(OfflineSyncService);
  });

  describe("processSyncBatch", () => {
    it("should process new offline action item and log audit", async () => {
      const result = await service.processSyncBatch("user-1", {
        items: [
          {
            clientActionId: "act-1",
            entityType: "ServiceRequest",
            action: "CREATE",
            payload: { roomNumber: "101" },
            clientTimestamp: "2026-09-03T10:00:00.000Z",
          },
        ],
      });

      expect(result.syncedCount).toBe(1);
      expect(result.status).toBe("SUCCESS");
      expect(prisma.auditLog.create).toHaveBeenCalled();
      expect(repo.createQueueItem).toHaveBeenCalled();
    });

    it("should handle clientActionId idempotently if action was already processed", async () => {
      repo.findExistingAction.mockResolvedValue({
        id: "existing-queue-1",
        clientActionId: "act-1",
        entityType: "ServiceRequest",
        action: "CREATE",
        status: SyncStatus.PROCESSED,
        payload: { roomNumber: "101" },
      });

      const result = await service.processSyncBatch("user-1", {
        items: [
          {
            clientActionId: "act-1",
            entityType: "ServiceRequest",
            action: "CREATE",
            payload: { roomNumber: "101" },
            clientTimestamp: "2026-09-03T10:00:00.000Z",
          },
        ],
      });

      expect(result.syncedCount).toBe(1);
      expect(result.items[0].id).toBe("existing-queue-1");
      expect(result.items[0].status).toBe(SyncStatus.PROCESSED);
      expect(repo.createQueueItem).not.toHaveBeenCalled();
    });

    it("should detect concurrent modification conflict on task update", async () => {
      prisma.task.findUnique.mockResolvedValue({
        id: "task-100",
        status: "IN_PROGRESS",
        updatedAt: new Date("2026-09-03T12:00:00.000Z"), // Newer than client timestamp
      });

      const result = await service.processSyncBatch("user-1", {
        items: [
          {
            clientActionId: "act-task-1",
            entityType: "Task",
            action: "UPDATE_STATUS",
            entityId: "task-100",
            payload: { status: "COMPLETED" },
            clientTimestamp: "2026-09-03T09:00:00.000Z", // Older client timestamp
          },
        ],
      });

      expect(result.status).toBe("PARTIAL_CONFLICT");
      expect(result.items[0].status).toBe(SyncStatus.CONFLICT);
    });
  });

  describe("retryItem", () => {
    it("should retry a failed sync item (FR-SYNC-006)", async () => {
      repo.findItemById.mockResolvedValue({
        id: "item-1",
        status: SyncStatus.FAILED,
        entityType: "Task",
        action: "UPDATE",
      });
      repo.updateItemStatus.mockResolvedValue({
        id: "item-1",
        entityType: "Task",
        action: "UPDATE",
        status: SyncStatus.PROCESSED,
        processedAt: new Date(),
      });

      const res = await service.retryItem("user-1", "item-1");
      expect(res.status).toBe(SyncStatus.PROCESSED);
      expect(repo.updateItemStatus).toHaveBeenCalledWith(
        "item-1",
        SyncStatus.PROCESSED,
        undefined,
      );
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });

  describe("resolveConflict", () => {
    it("should resolve conflict with CLIENT_WINS (FR-SYNC-007)", async () => {
      repo.findItemById.mockResolvedValue({
        id: "item-conflict",
        status: SyncStatus.CONFLICT,
        payload: { room: "101", notes: "client update" },
      });
      repo.updateItemStatus.mockResolvedValue({
        id: "item-conflict",
        status: SyncStatus.PROCESSED,
        processedAt: new Date(),
      });

      const res = await service.resolveConflict("user-1", "item-conflict", {
        strategy: ConflictResolutionStrategy.CLIENT_WINS,
      });

      expect(res.status).toBe(SyncStatus.PROCESSED);
      expect(res.strategyApplied).toBe(ConflictResolutionStrategy.CLIENT_WINS);
      expect(prisma.auditLog.create).toHaveBeenCalled();
    });
  });
});
