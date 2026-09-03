import { Test, TestingModule } from "@nestjs/testing";
import { SchedulerService } from "./scheduler.service";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { TaskStatus } from "@prisma/client";

describe("SchedulerService", () => {
  let service: SchedulerService;
  let prisma: any;
  let notifications: any;

  beforeEach(async () => {
    prisma = {
      task: {
        findMany: jest.fn().mockResolvedValue([
          { id: "task-1", title: "Urgent Maintenance", assignedToId: "user-1" },
        ]),
        update: jest.fn().mockResolvedValue({ id: "task-1", status: TaskStatus.OVERDUE }),
      },
      userDeviceSession: {
        deleteMany: jest.fn().mockResolvedValue({ count: 5 }),
      },
      offlineSyncQueue: {
        findMany: jest.fn().mockResolvedValue([
          { id: "sync-1" },
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

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SchedulerService,
        { provide: PrismaService, useValue: prisma },
        { provide: NotificationsService, useValue: notifications },
      ],
    }).compile();

    service = module.get<SchedulerService>(SchedulerService);
  });

  it("should list registered jobs", async () => {
    const jobs = await service.listJobs();
    expect(jobs.length).toBe(4);
    expect(jobs.some((j) => j.name === "task-overdue-checker")).toBe(true);
    expect(jobs.some((j) => j.name === "session-cleanup")).toBe(true);
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
});
