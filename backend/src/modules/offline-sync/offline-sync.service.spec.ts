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
      findQueue: jest.fn(),
      findItemById: jest.fn(),
      updateItemStatus: jest.fn(),
      findLogs: jest.fn(),
    };

    prisma = {
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
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
    it("should enqueue batch items and log audit", async () => {
      repo.enqueueBatch.mockResolvedValue([
        {
          id: "queue-1",
          entityType: "ServiceRequest",
          action: "CREATE",
          status: SyncStatus.PROCESSED,
        },
      ]);

      const result = await service.processSyncBatch("user-1", {
        items: [
          {
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
