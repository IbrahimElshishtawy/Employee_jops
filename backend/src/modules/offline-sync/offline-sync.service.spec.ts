import { Test, TestingModule } from "@nestjs/testing";
import { OfflineSyncService } from "./offline-sync.service";
import { OfflineSyncRepository } from "./offline-sync.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { SyncStatus } from "@prisma/client";

describe("OfflineSyncService", () => {
  let service: OfflineSyncService;
  let repo: jest.Mocked<OfflineSyncRepository>;
  let prisma: any;

  beforeEach(async () => {
    const mockRepo = {
      enqueueBatch: jest.fn(),
      findQueue: jest.fn(),
      updateItemStatus: jest.fn(),
    };

    const mockPrisma = {
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OfflineSyncService,
        { provide: OfflineSyncRepository, useValue: mockRepo },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<OfflineSyncService>(OfflineSyncService);
    repo = module.get(OfflineSyncRepository);
    prisma = module.get(PrismaService);
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
      ] as any);

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
});
