import { SchedulerService } from "./scheduler.service";
import { DistributedLockService } from "./distributed-lock.service";

describe("Scheduler Multi-Instance Distributed Coordination", () => {
  let lockService: DistributedLockService;
  let mockPrisma: any;
  let mockNotifications: any;
  let mockOfflineSync: any;
  let configService: any;

  beforeEach(() => {
    configService = {
      get: jest.fn().mockImplementation((key: string) => {
        if (key === "redis.host") return "localhost";
        if (key === "redis.port") return 6379;
        return undefined;
      }),
    };

    lockService = new DistributedLockService(configService);
    // Uses the local in-memory lock registry fallback (simulating shared cluster state)

    mockPrisma = {
      task: {
        findMany: jest.fn().mockResolvedValue([]),
        update: jest.fn(),
      },
      userDeviceSession: {
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      offlineSyncQueue: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      attendanceRecord: {
        findMany: jest.fn().mockResolvedValue([]),
      },
    };

    mockNotifications = {
      sendNotification: jest.fn().mockResolvedValue({ id: "notif-1" }),
    };

    mockOfflineSync = {
      applyEntityOperation: jest.fn().mockResolvedValue({ status: "PROCESSED" }),
    };
  });

  it("Single Instance: should execute scheduled job normally", async () => {
    const instance1 = new SchedulerService(
      mockPrisma,
      mockNotifications,
      lockService,
      mockOfflineSync,
    );

    const result = await instance1.executeJob("task-overdue-checker");
    expect(result.status).toBe("SUCCESS");
  });

  it("Two Instances: simultaneous execution allows exactly ONE to execute while the other skips", async () => {
    const instance1 = new SchedulerService(
      mockPrisma,
      mockNotifications,
      lockService,
      mockOfflineSync,
    );
    const instance2 = new SchedulerService(
      mockPrisma,
      mockNotifications,
      lockService,
      mockOfflineSync,
    );

    // Mock a job fn that holds the execution for 50ms so concurrency overlaps
    let businessLogicExecutionCount = 0;
    (instance1 as any).jobs.get("task-overdue-checker").fn = async () => {
      businessLogicExecutionCount++;
      await new Promise((resolve) => setTimeout(resolve, 50));
      return { processed: 1 };
    };
    (instance2 as any).jobs.get("task-overdue-checker").fn = async () => {
      businessLogicExecutionCount++;
      await new Promise((resolve) => setTimeout(resolve, 50));
      return { processed: 1 };
    };

    // Launch both simultaneously
    const [res1, res2] = await Promise.all([
      instance1.executeJob("task-overdue-checker"),
      instance2.executeJob("task-overdue-checker"),
    ]);

    const statuses = [res1.status, res2.status];
    expect(statuses).toContain("SUCCESS");
    expect(statuses).toContain("SKIPPED");
    expect(businessLogicExecutionCount).toBe(1);
  });

  it("Three Instances: simultaneous execution allows exactly ONE to execute while TWO skip", async () => {
    const instance1 = new SchedulerService(
      mockPrisma,
      mockNotifications,
      lockService,
      mockOfflineSync,
    );
    const instance2 = new SchedulerService(
      mockPrisma,
      mockNotifications,
      lockService,
      mockOfflineSync,
    );
    const instance3 = new SchedulerService(
      mockPrisma,
      mockNotifications,
      lockService,
      mockOfflineSync,
    );

    let businessLogicExecutionCount = 0;
    const workerFn = async () => {
      businessLogicExecutionCount++;
      await new Promise((resolve) => setTimeout(resolve, 60));
      return { processed: 1 };
    };

    (instance1 as any).jobs.get("session-cleanup").fn = workerFn;
    (instance2 as any).jobs.get("session-cleanup").fn = workerFn;
    (instance3 as any).jobs.get("session-cleanup").fn = workerFn;

    const [res1, res2, res3] = await Promise.all([
      instance1.executeJob("session-cleanup"),
      instance2.executeJob("session-cleanup"),
      instance3.executeJob("session-cleanup"),
    ]);

    const results = [res1, res2, res3];
    const successful = results.filter((r) => r.status === "SUCCESS");
    const skipped = results.filter((r) => r.status === "SKIPPED");

    expect(successful.length).toBe(1);
    expect(skipped.length).toBe(2);
    expect(skipped[0].reason).toBe("LOCKED_BY_ANOTHER_INSTANCE");
    expect(skipped[1].reason).toBe("LOCKED_BY_ANOTHER_INSTANCE");
    expect(businessLogicExecutionCount).toBe(1);
  });
});
