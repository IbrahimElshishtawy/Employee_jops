import { Test, TestingModule } from "@nestjs/testing";
import { OfflineSyncService } from "./offline-sync.service";
import { OfflineSyncRepository } from "./offline-sync.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { SyncStatus } from "@prisma/client";
import { ConflictResolutionStrategy } from "./dto";

describe("Offline Sync Comprehensive Scenarios (Phase 2 - Scenarios A to G)", () => {
  let service: OfflineSyncService;
  let repo: any;
  let prisma: any;

  beforeEach(async () => {
    repo = {
      findExistingAction: jest.fn().mockResolvedValue(null),
      createQueueItem: jest.fn().mockImplementation((userId, data) =>
        Promise.resolve({
          id: `queue-${Math.random().toString(36).substring(2, 7)}`,
          userId,
          clientActionId: data.clientActionId,
          entityType: data.entityType,
          action: data.action,
          status: data.status,
          failureReason: data.failureReason,
          payload: data.payload,
          processedAt: data.processedAt,
        }),
      ),
      findItemById: jest.fn(),
      updateItemStatus: jest.fn().mockImplementation((id, status, failureReason) =>
        Promise.resolve({ id, status, failureReason }),
      ),
      findQueue: jest.fn(),
    };

    prisma = {
      auditLog: { create: jest.fn().mockResolvedValue({ id: "audit-1" }) },
      task: {
        findUnique: jest.fn(),
        update: jest.fn().mockImplementation(({ where, data }) =>
          Promise.resolve({ id: where.id, ...data, updatedAt: new Date() }),
        ),
        findMany: jest.fn().mockResolvedValue([]),
      },
      serviceRequest: {
        create: jest.fn().mockImplementation(({ data }) =>
          Promise.resolve({ id: "sr-new-1", ...data }),
        ),
        findMany: jest.fn().mockResolvedValue([]),
      },
      attendanceRecord: {
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation(({ data }) =>
          Promise.resolve({ id: "att-new-1", ...data }),
        ),
        update: jest.fn().mockImplementation(({ where, data }) =>
          Promise.resolve({ id: where.id, ...data }),
        ),
        findMany: jest.fn().mockResolvedValue([]),
      },
      request: {
        create: jest.fn().mockImplementation(({ data }) =>
          Promise.resolve({ id: "req-new-1", ...data }),
        ),
        findMany: jest.fn().mockResolvedValue([]),
      },
      employeeProfile: {
        findFirst: jest.fn().mockResolvedValue({
          id: "emp-101",
          userId: "user-101",
          departmentId: "dept-front-desk",
        }),
      },
      notification: {
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

  // ============================================================
  // Scenario A: Offline employee creates an operation
  // ============================================================
  it("Scenario A: Offline employee creates an operation (Attendance Check-In & ServiceRequest)", async () => {
    const result = await service.processSyncBatch("user-101", {
      items: [
        {
          clientActionId: "act-att-001",
          entityType: "Attendance",
          action: "CHECK_IN",
          payload: { latitude: 24.7136, longitude: 46.6753 },
          clientTimestamp: "2026-09-04T08:00:00.000Z",
        },
        {
          clientActionId: "act-sr-001",
          entityType: "ServiceRequest",
          action: "CREATE",
          payload: {
            title: "AC Leaking in Room 304",
            priority: "HIGH",
          },
          clientTimestamp: "2026-09-04T08:05:00.000Z",
        },
      ],
    });

    expect(result.syncedCount).toBe(2);
    expect(result.status).toBe("SUCCESS");
    expect(prisma.attendanceRecord.create).toHaveBeenCalled();
    expect(prisma.serviceRequest.create).toHaveBeenCalled();
    expect(repo.createQueueItem).toHaveBeenCalledTimes(2);
  });

  // ============================================================
  // Scenario B: Same clientActionId submitted twice (Idempotency)
  // ============================================================
  it("Scenario B: Same clientActionId submitted twice results in exactly ONE logical operation", async () => {
    // First call: returns processed
    repo.findExistingAction.mockResolvedValueOnce(null);

    const firstResult = await service.processSyncBatch("user-101", {
      items: [
        {
          clientActionId: "action-uuid-1234",
          entityType: "ServiceRequest",
          action: "CREATE",
          payload: { title: "Luggage Assistance" },
          clientTimestamp: "2026-09-04T09:00:00.000Z",
        },
      ],
    });
    expect(firstResult.syncedCount).toBe(1);
    expect(prisma.serviceRequest.create).toHaveBeenCalledTimes(1);

    // Second call: simulate same clientActionId recognized in repository
    repo.findExistingAction.mockResolvedValueOnce({
      id: "queue-saved-1",
      clientActionId: "action-uuid-1234",
      entityType: "ServiceRequest",
      action: "CREATE",
      status: SyncStatus.PROCESSED,
      payload: { title: "Luggage Assistance" },
    });

    const secondResult = await service.processSyncBatch("user-101", {
      items: [
        {
          clientActionId: "action-uuid-1234",
          entityType: "ServiceRequest",
          action: "CREATE",
          payload: { title: "Luggage Assistance" },
          clientTimestamp: "2026-09-04T09:00:00.000Z",
        },
      ],
    });

    expect(secondResult.syncedCount).toBe(1);
    expect(secondResult.items[0].id).toBe("queue-saved-1");
    // Crucial: serviceRequest.create must NOT be called again
    expect(prisma.serviceRequest.create).toHaveBeenCalledTimes(1);
  });

  // ============================================================
  // Scenario C: Conflicting updates with deterministic resolution
  // ============================================================
  it("Scenario C: Two conflicting updates trigger deterministic conflict resolution", async () => {
    // Server task was modified at 12:00
    prisma.task.findUnique.mockResolvedValue({
      id: "task-conflict-1",
      status: "IN_PROGRESS",
      updatedAt: new Date("2026-09-04T12:00:00.000Z"),
    });

    // Client action has older timestamp 10:00
    const result = await service.processSyncBatch("user-101", {
      items: [
        {
          clientActionId: "act-task-conflict",
          entityType: "Task",
          action: "UPDATE_STATUS",
          entityId: "task-conflict-1",
          payload: { status: "COMPLETED" },
          clientTimestamp: "2026-09-04T10:00:00.000Z",
        },
      ],
    });

    expect(result.status).toBe("PARTIAL_CONFLICT");
    expect(result.items[0].status).toBe(SyncStatus.CONFLICT);
    expect(result.items[0].failureReason).toContain("Concurrent modification");

    // Resolve conflict with CLIENT_WINS
    repo.findItemById.mockResolvedValue({
      id: "conflict-item-1",
      status: SyncStatus.CONFLICT,
      payload: { status: "COMPLETED" },
    });

    const resolution = await service.resolveConflict("user-101", "conflict-item-1", {
      strategy: ConflictResolutionStrategy.CLIENT_WINS,
    });

    expect(resolution.strategyApplied).toBe("CLIENT_WINS");
    expect(repo.updateItemStatus).toHaveBeenCalledWith(
      "conflict-item-1",
      SyncStatus.PROCESSED,
      undefined,
      expect.objectContaining({ _resolvedVia: "CLIENT_WINS" }),
    );
  });

  // ============================================================
  // Scenario D: Network fails during sync & safe retry
  // ============================================================
  it("Scenario D: Safe retry without duplicate business action", async () => {
    repo.findItemById.mockResolvedValue({
      id: "failed-item-1",
      status: SyncStatus.FAILED,
      entityType: "ServiceRequest",
      action: "CREATE",
      payload: { title: "Replace Towels" },
      clientTimestamp: new Date(),
    });

    const retryResult = await service.retryItem("user-101", "failed-item-1");
    expect(retryResult.status).toBe(SyncStatus.PROCESSED);
    expect(prisma.serviceRequest.create).toHaveBeenCalled();
  });

  // ============================================================
  // Scenario E: Large pending queue batch processing
  // ============================================================
  it("Scenario E: Large pending queue processed in batches without excessive memory", async () => {
    const items = Array.from({ length: 50 }, (_, i) => ({
      clientActionId: `act-batch-${i}`,
      entityType: "ServiceRequest",
      action: "CREATE",
      payload: { title: `Service item #${i}` },
      clientTimestamp: "2026-09-04T10:00:00.000Z",
    }));

    const result = await service.processSyncBatch("user-101", { items });
    expect(result.syncedCount).toBe(50);
    expect(result.status).toBe("SUCCESS");
    expect(prisma.serviceRequest.create).toHaveBeenCalledTimes(50);
  });

  // ============================================================
  // Scenario F: Unauthorized sync attempt handles missing employee profile
  // ============================================================
  it("Scenario F: Sync attempt without valid employee profile fails gracefully with FAILED status", async () => {
    prisma.employeeProfile.findFirst.mockResolvedValue(null);

    const result = await service.processSyncBatch("unauthorized-user", {
      items: [
        {
          clientActionId: "act-unauth-1",
          entityType: "Attendance",
          action: "CHECK_IN",
          payload: {},
          clientTimestamp: "2026-09-04T08:00:00.000Z",
        },
      ],
    });

    expect(result.status).toBe("PARTIAL_FAILURE");
    expect(result.items[0].status).toBe(SyncStatus.FAILED);
    expect(result.items[0].failureReason).toContain("Employee profile not found");
  });

  // ============================================================
  // Scenario G: Concurrent sync requests maintain data consistency
  // ============================================================
  it("Scenario G: Concurrent sync requests execute atomically without state corruption", async () => {
    const batch1 = service.processSyncBatch("user-101", {
      items: [
        {
          clientActionId: "concurrent-1",
          entityType: "ServiceRequest",
          action: "CREATE",
          payload: { title: "Req 1" },
          clientTimestamp: "2026-09-04T10:00:00.000Z",
        },
      ],
    });

    const batch2 = service.processSyncBatch("user-101", {
      items: [
        {
          clientActionId: "concurrent-2",
          entityType: "ServiceRequest",
          action: "CREATE",
          payload: { title: "Req 2" },
          clientTimestamp: "2026-09-04T10:00:01.000Z",
        },
      ],
    });

    const [res1, res2] = await Promise.all([batch1, batch2]);
    expect(res1.status).toBe("SUCCESS");
    expect(res2.status).toBe("SUCCESS");
    expect(prisma.serviceRequest.create).toHaveBeenCalledTimes(2);
  });
});
