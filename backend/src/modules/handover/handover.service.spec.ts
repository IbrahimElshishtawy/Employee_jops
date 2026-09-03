import { Test, TestingModule } from "@nestjs/testing";
import { HandoverService } from "./handover.service";
import { HandoverRepository } from "./handover.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { HandoverAccessGuard } from "./guards/handover-access.guard";
import {
  AuditAction,
  HandoverItemCategory,
  HandoverItemPriority,
  HandoverStatus,
  NotificationType,
  Role,
  TaskPriority,
  TaskStatus,
  UserStatus,
} from "@prisma/client";
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from "@nestjs/common";

describe("HandoverService (Phase 7 Shift Handover)", () => {
  let service: HandoverService;
  let guard: HandoverAccessGuard;

  // In-Memory Fixtures
  const mockGiverUser = {
    id: "user-giver-1",
    role: Role.SUPERVISOR,
    status: UserStatus.ACTIVE,
  };

  const mockGiverProfile = {
    id: "emp-giver-1",
    userId: "user-giver-1",
    employeeCode: "CW-M01",
    firstName: "Khaled",
    lastName: "Mahmoud",
    departmentId: "dept-ops",
    user: mockGiverUser,
  };

  const mockReceiverUser = {
    id: "user-receiver-1",
    role: Role.SUPERVISOR,
    status: UserStatus.ACTIVE,
  };

  const mockReceiverProfile = {
    id: "emp-receiver-1",
    userId: "user-receiver-1",
    employeeCode: "CW-E01",
    firstName: "Samir",
    lastName: "Adel",
    departmentId: "dept-ops",
    user: mockReceiverUser,
  };

  const mockDepartment = {
    id: "dept-ops",
    name: "Operations & Facility",
    code: "OPS",
    isActive: true,
    headOfDepartmentId: "emp-head-ops",
    headOfDepartment: {
      id: "emp-head-ops",
      userId: "user-head-ops",
    },
  };

  let mockHandovers: any[] = [];
  let mockItems: any[] = [];
  let mockAuditLogs: any[] = [];
  let mockNotifications: any[] = [];

  const mockPrismaService: any = {
    user: {
      findUnique: jest.fn(({ where }) => {
        if (where.id === "user-giver-1")
          return Promise.resolve({
            ...mockGiverUser,
            employeeProfile: mockGiverProfile,
          });
        if (where.id === "user-receiver-1")
          return Promise.resolve({
            ...mockReceiverUser,
            employeeProfile: mockReceiverProfile,
          });
        if (where.id === "user-stranger")
          return Promise.resolve({
            id: "user-stranger",
            role: Role.EMPLOYEE,
            status: UserStatus.ACTIVE,
            employeeProfile: { id: "emp-stranger", departmentId: "dept-hr" },
          });
        return Promise.resolve(null);
      }),
    },
    employeeProfile: {
      findUnique: jest.fn(({ where }) => {
        if (where.userId === "user-giver-1" || where.id === "emp-giver-1")
          return Promise.resolve(mockGiverProfile);
        if (where.userId === "user-receiver-1" || where.id === "emp-receiver-1")
          return Promise.resolve(mockReceiverProfile);
        return Promise.resolve(null);
      }),
    },
    department: {
      findUnique: jest.fn(({ where }) => {
        if (where.id === "dept-ops") return Promise.resolve(mockDepartment);
        return Promise.resolve(null);
      }),
    },
    task: {
      findMany: jest.fn(() =>
        Promise.resolve([
          {
            id: "task-open-1",
            title: "Inspect generator fuel level",
            description: "Scheduled daily inspection",
            priority: TaskPriority.HIGH,
            status: TaskStatus.IN_PROGRESS,
            dueDate: new Date(),
            assignee: {
              id: "emp-giver-1",
              firstName: "Khaled",
              lastName: "Mahmoud",
            },
          },
        ]),
      ),
    },
    shiftHandover: {
      count: jest.fn(() => Promise.resolve(mockHandovers.length)),
      create: jest.fn(({ data }) => {
        const items = data.items?.create || [];
        const ho = {
          id: `ho-${mockHandovers.length + 1}`,
          ...data,
          createdAt: new Date(),
          updatedAt: new Date(),
          handedOverBy: mockGiverProfile,
          receivedBy: data.receivedById ? mockReceiverProfile : null,
          department: mockDepartment,
          items: items.map((it: any, idx: number) => ({
            id: `item-${idx + 1}`,
            ...it,
          })),
        };
        mockHandovers.push(ho);
        return Promise.resolve(ho);
      }),
      findUnique: jest.fn(({ where }) => {
        const found = mockHandovers.find((h) => h.id === where.id);
        if (!found) return Promise.resolve(null);
        return Promise.resolve({
          ...found,
          handedOverBy: mockGiverProfile,
          receivedBy: found.receivedById ? mockReceiverProfile : null,
          department: mockDepartment,
          items: found.items || [],
        });
      }),
      update: jest.fn(({ where, data }) => {
        const found = mockHandovers.find((h) => h.id === where.id);
        if (!found) throw new Error("Not found");
        Object.assign(found, data);
        return Promise.resolve(found);
      }),
    },
    shiftHandoverItem: {
      create: jest.fn(({ data }) => {
        const it = {
          id: `item-${mockItems.length + 1}`,
          ...data,
          createdAt: new Date(),
        };
        mockItems.push(it);
        return Promise.resolve(it);
      }),
    },
    auditLog: {
      create: jest.fn(({ data }) => {
        mockAuditLogs.push(data);
        return Promise.resolve(data);
      }),
    },
  };

  const mockNotificationsService = {
    sendNotification: jest.fn((userId, title, body, type, data) => {
      mockNotifications.push({ userId, title, body, type, data });
      return Promise.resolve(true);
    }),
  };

  beforeEach(async () => {
    mockHandovers = [];
    mockItems = [];
    mockAuditLogs = [];
    mockNotifications = [];

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        HandoverService,
        HandoverRepository,
        HandoverAccessGuard,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: NotificationsService, useValue: mockNotificationsService },
      ],
    }).compile();

    service = module.get<HandoverService>(HandoverService);
    guard = module.get<HandoverAccessGuard>(HandoverAccessGuard);

    jest.clearAllMocks();
  });

  describe("1. Shift Handover Creation & Task Capture", () => {
    it("should successfully create shift handover and auto-capture open department tasks", async () => {
      const created = await service.createHandover("user-giver-1", {
        shiftDate: "2026-09-03",
        shiftName: "Morning Shift",
        departmentId: "dept-ops",
        receivedById: "emp-receiver-1",
        summary:
          "Normal morning operations completed. Generator inspection ongoing.",
        includeOpenTasks: true,
        items: [
          {
            title: "Access badges returned",
            category: HandoverItemCategory.ASSET,
            priority: HandoverItemPriority.LOW,
            requiresAction: false,
          },
        ],
      });

      expect(created.id).toBeDefined();
      expect(created.handoverNumber).toMatch(/^HO-\d{8}-\d{4}$/);
      expect(created.status).toBe(HandoverStatus.PENDING_ACKNOWLEDGEMENT);

      // Verify items: 1 manual item + 1 auto-captured open task
      expect(created.items.length).toBe(2);
      expect(
        created.items.some((i: any) =>
          i.title.includes("generator fuel level"),
        ),
      ).toBe(true);

      // Verify Audit Log
      const audit = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.HANDOVER_CREATED &&
          a.entityId === created.id,
      );
      expect(audit).toBeDefined();

      // Verify Notification sent to receiver
      const notif = mockNotifications.find(
        (n) =>
          n.userId === "user-receiver-1" &&
          n.type === NotificationType.HANDOVER_SUBMITTED,
      );
      expect(notif).toBeDefined();
    });

    it("should prevent self-handover", async () => {
      await expect(
        service.createHandover("user-giver-1", {
          shiftDate: "2026-09-03",
          shiftName: "Morning Shift",
          departmentId: "dept-ops",
          receivedById: "emp-giver-1", // Self
          summary: "Attempting self handover",
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe("2. Shift Handover Acknowledgement & Discrepancies", () => {
    let hoId: string;

    beforeEach(async () => {
      const ho = await service.createHandover("user-giver-1", {
        shiftDate: "2026-09-03",
        shiftName: "Morning Shift",
        departmentId: "dept-ops",
        receivedById: "emp-receiver-1",
        summary: "Shift handover test",
      });
      hoId = ho.id;
    });

    it("should allow next shift receiver to acknowledge handover", async () => {
      const ack = await service.acknowledgeHandover(hoId, "user-receiver-1", {
        action: "ACKNOWLEDGE",
        acknowledgementNotes:
          "Shift custody accepted. All equipment accounted for.",
      });

      expect(ack.status).toBe(HandoverStatus.ACKNOWLEDGED);
      expect(ack.acknowledgedAt).toBeDefined();
      expect(ack.acknowledgementNotes).toContain("Shift custody accepted");

      // Verify Audit Log
      const audit = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.HANDOVER_ACKNOWLEDGED && a.entityId === hoId,
      );
      expect(audit).toBeDefined();

      // Outgoing shift notified
      const notif = mockNotifications.find(
        (n) =>
          n.userId === "user-giver-1" &&
          n.type === NotificationType.HANDOVER_ACKNOWLEDGED,
      );
      expect(notif).toBeDefined();
    });

    it("should prevent duplicate acknowledgement on already acknowledged handover", async () => {
      await service.acknowledgeHandover(hoId, "user-receiver-1", {
        action: "ACKNOWLEDGE",
      });

      await expect(
        service.acknowledgeHandover(hoId, "user-receiver-1", {
          action: "ACKNOWLEDGE",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should prevent outgoing giver from acknowledging their own handover", async () => {
      await expect(
        service.acknowledgeHandover(hoId, "user-giver-1", {
          action: "ACKNOWLEDGE",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("should prevent unauthorized stranger from acknowledging handover", async () => {
      await expect(
        service.acknowledgeHandover(hoId, "user-stranger", {
          action: "ACKNOWLEDGE",
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it("should allow flagging handover with mandatory discrepancy notes", async () => {
      // Flag without discrepancy notes throws
      await expect(
        service.acknowledgeHandover(hoId, "user-receiver-1", {
          action: "FLAG",
          discrepancyNotes: "",
        }),
      ).rejects.toThrow(BadRequestException);

      const flagged = await service.acknowledgeHandover(
        hoId,
        "user-receiver-1",
        {
          action: "FLAG",
          discrepancyNotes: "Radio #4 battery is dead and charger missing.",
        },
      );

      expect(flagged.status).toBe(HandoverStatus.FLAGGED);
      expect(flagged.discrepancyNotes).toContain("Radio #4 battery");

      // Audit Log reflects disputed handover
      const audit = mockAuditLogs.find(
        (a) =>
          a.action === AuditAction.HANDOVER_DISPUTED && a.entityId === hoId,
      );
      expect(audit).toBeDefined();
    });
  });

  describe("3. Adding Handover Items", () => {
    let hoId: string;

    beforeEach(async () => {
      const ho = await service.createHandover("user-giver-1", {
        shiftDate: "2026-09-03",
        shiftName: "Morning Shift",
        departmentId: "dept-ops",
        summary: "Shift handover test",
      });
      hoId = ho.id;
    });

    it("should add new item to pending handover", async () => {
      const item = await service.addItem(hoId, "user-giver-1", {
        title: "Key for Server Room handed to IT",
        category: HandoverItemCategory.ASSET,
        priority: HandoverItemPriority.MEDIUM,
      });

      expect(item.id).toBeDefined();
      expect(item.title).toBe("Key for Server Room handed to IT");
    });

    it("should prevent adding items to an already acknowledged handover", async () => {
      await service.acknowledgeHandover(hoId, "user-receiver-1", {
        action: "ACKNOWLEDGE",
      });

      await expect(
        service.addItem(hoId, "user-giver-1", {
          title: "Late addition",
          category: HandoverItemCategory.GENERAL,
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
