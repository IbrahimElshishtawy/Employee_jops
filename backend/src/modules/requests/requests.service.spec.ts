import { Test, TestingModule } from "@nestjs/testing";
import { RequestsService } from "./requests.service";
import { RequestsRepository } from "./requests.repository";
import { WorkflowService } from "../workflow/workflow.service";
import { WorkflowRepository } from "../workflow/workflow.repository";
import { ApprovalsService } from "../approvals/approvals.service";
import { ApprovalsRepository } from "../approvals/approvals.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  RequestType,
  RequestStatus,
  HalfDayPeriod,
  Role,
  UserStatus,
  AuditAction,
  AttendanceStatus,
} from "@prisma/client";
import { BadRequestException, ForbiddenException } from "@nestjs/common";

describe("Phase 04 — Employee Requests & Leave Management (30 Mandatory Scenarios)", () => {
  let requestsService: RequestsService;
  let prismaService: any;
  let notificationsService: any;

  // Mock State Stores
  const mockUsers: Record<string, any> = {
    "user-emp-1": {
      id: "user-emp-1",
      email: "emp1@cyberwise.test",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-profile-1",
        userId: "user-emp-1",
        employeeCode: "CW-0010",
        firstName: "Ahmed",
        lastName: "Mansour",
        department: "Engineering",
      },
    },
    "user-emp-2": {
      id: "user-emp-2",
      email: "emp2@cyberwise.test",
      role: Role.EMPLOYEE,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-profile-2",
        userId: "user-emp-2",
        employeeCode: "CW-0020",
        firstName: "Sara",
        lastName: "Khaled",
        department: "Design",
      },
    },
    "user-inactive": {
      id: "user-inactive",
      email: "inactive@cyberwise.test",
      role: Role.EMPLOYEE,
      status: UserStatus.SUSPENDED,
      employeeProfile: {
        id: "emp-profile-suspended",
        userId: "user-inactive",
        employeeCode: "CW-0099",
        firstName: "Suspended",
        lastName: "User",
      },
    },
    "user-hr-admin": {
      id: "user-hr-admin",
      email: "hr@cyberwise.test",
      role: Role.HR_ADMIN,
      status: UserStatus.ACTIVE,
      employeeProfile: {
        id: "emp-profile-hr",
        userId: "user-hr-admin",
        employeeCode: "CW-HR01",
        firstName: "HR",
        lastName: "Manager",
      },
    },
  };

  let mockRequests: any[] = [];
  let mockLeaveBalances: any[] = [];
  let mockAttendanceRecords: any[] = [];
  let mockAuditLogs: any[] = [];
  let mockNotifications: any[] = [];

  beforeEach(async () => {
    mockRequests = [];
    mockLeaveBalances = [
      {
        id: "balance-1",
        employeeId: "emp-profile-1",
        leaveType: RequestType.ANNUAL_LEAVE,
        year: 2026,
        totalDays: 21,
        usedDays: 0,
        pendingDays: 0,
        remainingDays: 21,
      },
      {
        id: "balance-low",
        employeeId: "emp-profile-2",
        leaveType: RequestType.ANNUAL_LEAVE,
        year: 2026,
        totalDays: 21,
        usedDays: 20,
        pendingDays: 0,
        remainingDays: 1,
      },
    ];
    mockAttendanceRecords = [];
    mockAuditLogs = [];
    mockNotifications = [];

    prismaService = {
      user: {
        findUnique: jest.fn(({ where }) => {
          return Promise.resolve(mockUsers[where.id] || null);
        }),
      },
      request: {
        findUnique: jest.fn(({ where }) => {
          if (where.id) {
            const req = mockRequests.find((r) => r.id === where.id);
            if (!req) return Promise.resolve(null);
            const user = Object.values(mockUsers).find(
              (u) => u.employeeProfile?.id === req.employeeId,
            );
            return Promise.resolve({
              ...req,
              employee: {
                ...user?.employeeProfile,
                user: { id: user?.id, email: user?.email },
              },
            });
          }
          if (where.idempotencyKey) {
            return Promise.resolve(
              mockRequests.find(
                (r) => r.idempotencyKey === where.idempotencyKey,
              ) || null,
            );
          }
          return Promise.resolve(null);
        }),
        findFirst: jest.fn(({ where }) => {
          return Promise.resolve(
            mockRequests.find(
              (r) =>
                r.employeeId === where.employeeId &&
                r.status === where.status &&
                r.startDate <= where.startDate?.lte &&
                r.endDate >= where.endDate?.gte,
            ) || null,
          );
        }),
        findMany: jest.fn(({ where, skip = 0, take = 10 }) => {
          let filtered = [...mockRequests];
          if (where.employeeId)
            filtered = filtered.filter(
              (r) => r.employeeId === where.employeeId,
            );
          if (where.status)
            filtered = filtered.filter((r) => r.status === where.status);
          if (where.type)
            filtered = filtered.filter((r) => r.type === where.type);
          return Promise.resolve(filtered.slice(skip, skip + take));
        }),
        count: jest.fn(({ where }) => {
          let filtered = [...mockRequests];
          if (where.employeeId)
            filtered = filtered.filter(
              (r) => r.employeeId === where.employeeId,
            );
          if (where.status)
            filtered = filtered.filter((r) => r.status === where.status);
          return Promise.resolve(filtered.length);
        }),
        create: jest.fn(({ data }) => {
          const newReq = {
            id: `req-${mockRequests.length + 1}`,
            status: RequestStatus.PENDING,
            createdAt: new Date(),
            updatedAt: new Date(),
            approvalSteps: [],
            ...data,
          };
          mockRequests.push(newReq);
          return Promise.resolve(newReq);
        }),
        update: jest.fn(({ where, data }) => {
          const index = mockRequests.findIndex((r) => r.id === where.id);
          if (index === -1) throw new Error("Not found");
          mockRequests[index] = {
            ...mockRequests[index],
            ...data,
            updatedAt: new Date(),
          };
          return Promise.resolve(mockRequests[index]);
        }),
      },
      leaveBalance: {
        findUnique: jest.fn(({ where }) => {
          if (where.id) {
            return Promise.resolve(
              mockLeaveBalances.find((b) => b.id === where.id) || null,
            );
          }
          if (where.employeeId_leaveType_year) {
            const { employeeId, leaveType, year } =
              where.employeeId_leaveType_year;
            return Promise.resolve(
              mockLeaveBalances.find(
                (b) =>
                  b.employeeId === employeeId &&
                  b.leaveType === leaveType &&
                  b.year === year,
              ) || null,
            );
          }
          return Promise.resolve(null);
        }),
        findMany: jest.fn(({ where }) => {
          let filtered = [...mockLeaveBalances];
          if (where.employeeId)
            filtered = filtered.filter(
              (b) => b.employeeId === where.employeeId,
            );
          if (where.year)
            filtered = filtered.filter((b) => b.year === where.year);
          return Promise.resolve(filtered);
        }),
        create: jest.fn(({ data }) => {
          const newBal = { id: `bal-${mockLeaveBalances.length + 1}`, ...data };
          mockLeaveBalances.push(newBal);
          return Promise.resolve(newBal);
        }),
        update: jest.fn(({ where, data }) => {
          const index = mockLeaveBalances.findIndex((b) => b.id === where.id);
          if (index !== -1) {
            mockLeaveBalances[index] = { ...mockLeaveBalances[index], ...data };
            return Promise.resolve(mockLeaveBalances[index]);
          }
          return Promise.resolve(null);
        }),
        upsert: jest.fn(({ where, update, create }) => {
          const { employeeId, leaveType, year } =
            where.employeeId_leaveType_year;
          const existing = mockLeaveBalances.find(
            (b) =>
              b.employeeId === employeeId &&
              b.leaveType === leaveType &&
              b.year === year,
          );
          if (existing) {
            if (update.usedDays?.increment)
              existing.usedDays += update.usedDays.increment;
            if (update.remainingDays?.decrement)
              existing.remainingDays -= update.remainingDays.decrement;
            return Promise.resolve(existing);
          } else {
            const newBal = {
              id: `bal-${mockLeaveBalances.length + 1}`,
              ...create,
            };
            mockLeaveBalances.push(newBal);
            return Promise.resolve(newBal);
          }
        }),
      },
      attendanceRecord: {
        findUnique: jest.fn(({ where }) => {
          return Promise.resolve(
            mockAttendanceRecords.find(
              (a) =>
                a.employeeId === where.employeeId_date?.employeeId &&
                a.date?.toISOString() ===
                  where.employeeId_date?.date?.toISOString(),
            ) || null,
          );
        }),
        upsert: jest.fn(({ where, update, create }) => {
          const index = mockAttendanceRecords.findIndex(
            (a) =>
              a.employeeId === where.employeeId_date?.employeeId &&
              a.date?.toISOString() ===
                where.employeeId_date?.date?.toISOString(),
          );
          if (index !== -1) {
            mockAttendanceRecords[index] = {
              ...mockAttendanceRecords[index],
              ...update,
            };
            return Promise.resolve(mockAttendanceRecords[index]);
          } else {
            const newAtt = {
              id: `att-${mockAttendanceRecords.length + 1}`,
              ...create,
            };
            mockAttendanceRecords.push(newAtt);
            return Promise.resolve(newAtt);
          }
        }),
        update: jest.fn(({ where, data }) => {
          const index = mockAttendanceRecords.findIndex(
            (a) => a.id === where.id,
          );
          if (index !== -1) {
            mockAttendanceRecords[index] = {
              ...mockAttendanceRecords[index],
              ...data,
            };
            return Promise.resolve(mockAttendanceRecords[index]);
          }
          return Promise.resolve(null);
        }),
      },
      auditLog: {
        create: jest.fn(({ data }) => {
          const newLog = {
            id: `audit-${mockAuditLogs.length + 1}`,
            ...data,
            createdAt: new Date(),
          };
          mockAuditLogs.push(newLog);
          return Promise.resolve(newLog);
        }),
      },
      approvalStep: {
        create: jest.fn(({ data }) =>
          Promise.resolve({
            id: `step-${Date.now()}`,
            createdAt: new Date(),
            ...data,
          }),
        ),
        findMany: jest.fn(() => Promise.resolve([])),
      },
      approvalDelegation: {
        findMany: jest.fn(() => Promise.resolve([])),
      },
      workflowDefinition: {
        findMany: jest.fn(() => Promise.resolve([])),
        findFirst: jest.fn(() => Promise.resolve(null)),
        findUnique: jest.fn(() => Promise.resolve(null)),
      },
      $transaction: jest.fn((callback) => callback(prismaService)),
    };

    notificationsService = {
      sendNotification: jest.fn((userId, title, body, type, data) => {
        const notif = {
          id: `notif-${mockNotifications.length + 1}`,
          userId,
          title,
          body,
          type,
          data,
        };
        mockNotifications.push(notif);
        return Promise.resolve(notif);
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RequestsService,
        RequestsRepository,
        WorkflowService,
        WorkflowRepository,
        ApprovalsService,
        ApprovalsRepository,
        { provide: PrismaService, useValue: prismaService },
        { provide: NotificationsService, useValue: notificationsService },
      ],
    }).compile();

    requestsService = module.get<RequestsService>(RequestsService);
  });

  // ============================================================
  // SCENARIOS
  // ============================================================

  it("1. Employee creates leave request (ANNUAL_LEAVE)", async () => {
    const res = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-05",
      reason: "Summer family vacation",
    });

    expect(res).toBeDefined();
    expect(res.status).toBe(RequestStatus.PENDING);
    expect(res.employeeId).toBe("emp-profile-1");
    expect(mockAuditLogs.length).toBe(1);
    expect(mockAuditLogs[0].action).toBe(AuditAction.REQUEST_CREATED);
  });

  it("2. Employee creates permission request (PERMISSION with startTime and endTime)", async () => {
    const res = await requestsService.create("user-emp-1", {
      type: RequestType.PERMISSION,
      startDate: "2026-09-10",
      endDate: "2026-09-10",
      startTime: "10:00",
      endTime: "12:00",
      reason: "Doctor appointment",
    });

    expect(res.type).toBe(RequestType.PERMISSION);
    expect(res.startTime).toBe("10:00");
    expect(res.endTime).toBe("12:00");
  });

  it("3. Employee creates absence request (ABSENCE)", async () => {
    const res = await requestsService.create("user-emp-1", {
      type: RequestType.ABSENCE,
      startDate: "2026-09-15",
      endDate: "2026-09-15",
      reason: "Urgent car repair issue",
    });

    expect(res.type).toBe(RequestType.ABSENCE);
    expect(res.status).toBe(RequestStatus.PENDING);
  });

  it("4. Employee creates half-day request (HALF_DAY with FIRST_HALF)", async () => {
    const res = await requestsService.create("user-emp-1", {
      type: RequestType.HALF_DAY,
      startDate: "2026-09-20",
      endDate: "2026-09-20",
      halfDayPeriod: HalfDayPeriod.FIRST_HALF,
      reason: "Morning errands",
    });

    expect(res.type).toBe(RequestType.HALF_DAY);
    expect(res.halfDayPeriod).toBe(HalfDayPeriod.FIRST_HALF);
  });

  it("5. Employee creates late excuse (LATE_EXCUSE)", async () => {
    const res = await requestsService.create("user-emp-1", {
      type: RequestType.LATE_EXCUSE,
      startDate: "2026-09-22",
      endDate: "2026-09-22",
      startTime: "09:30",
      endTime: "10:00",
      reason: "Severe traffic accident on highway",
    });

    expect(res.type).toBe(RequestType.LATE_EXCUSE);
  });

  it("6. Employee creates early-leave request (EARLY_LEAVE)", async () => {
    const res = await requestsService.create("user-emp-1", {
      type: RequestType.EARLY_LEAVE,
      startDate: "2026-09-25",
      endDate: "2026-09-25",
      startTime: "15:00",
      endTime: "17:00",
      reason: "Family emergency",
    });

    expect(res.type).toBe(RequestType.EARLY_LEAVE);
  });

  it("7. Employee sees own submitted requests history", async () => {
    await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03",
      reason: "Trip",
    });

    const res = await requestsService.findMyRequests("emp-profile-1");
    expect(res.data.length).toBe(1);
    expect(res.meta.total).toBe(1);
  });

  it("8. Employee cannot see another employee request (IDOR protection)", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03",
      reason: "Trip",
    });

    // Employee 2 tries to view Employee 1's request
    await expect(
      requestsService.findOne(req.id, {
        id: "user-emp-2",
        role: Role.EMPLOYEE,
        employeeProfileId: "emp-profile-2",
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  it("9. HR sees request queue with filters and pagination", async () => {
    await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03",
      reason: "Trip 1",
    });
    await requestsService.create("user-emp-2", {
      type: RequestType.SICK_LEAVE,
      startDate: "2026-09-05",
      endDate: "2026-09-06",
      reason: "Trip 2",
    });

    const res = await requestsService.findAll({ page: 1, limit: 10 });
    expect(res.data.length).toBe(2);
    expect(res.meta.total).toBe(2);
  });

  it("10. HR approves pending request successfully", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03",
      reason: "Vacation",
    });

    const approved = await requestsService.approve(req.id, "user-hr-admin", {
      comment: "Approved by HR Director",
    });

    expect(approved.status).toBe(RequestStatus.APPROVED);
    expect(
      mockAuditLogs.some((l) => l.action === AuditAction.REQUEST_APPROVED),
    ).toBe(true);
    expect(notificationsService.sendNotification).toHaveBeenCalled();
  });

  it("11. HR rejects pending request with reason", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03",
      reason: "Vacation",
    });

    const rejected = await requestsService.reject(req.id, "user-hr-admin", {
      reason: "Insufficient team coverage",
    });

    expect(rejected.status).toBe(RequestStatus.REJECTED);
    expect(rejected.rejectionReason).toBe("Insufficient team coverage");
    expect(
      mockAuditLogs.some((l) => l.action === AuditAction.REQUEST_REJECTED),
    ).toBe(true);
  });

  it("12. Rejection requires non-empty reason", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03",
      reason: "Vacation",
    });

    await expect(
      requestsService.reject(req.id, "user-hr-admin", { reason: "" }),
    ).rejects.toThrow(BadRequestException);
  });

  it("13. Employee cancels own pending request", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03",
      reason: "Vacation",
    });

    const cancelled = await requestsService.cancel(
      req.id,
      {
        id: "user-emp-1",
        employeeProfileId: "emp-profile-1",
        role: Role.EMPLOYEE,
      },
      { reason: "Trip cancelled" },
    );

    expect(cancelled.status).toBe(RequestStatus.CANCELLED);
    expect(
      mockAuditLogs.some((l) => l.action === AuditAction.REQUEST_CANCELLED),
    ).toBe(true);
  });

  it("14. Employee cannot cancel another employee request", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03",
      reason: "Vacation",
    });

    await expect(
      requestsService.cancel(req.id, {
        id: "user-emp-2",
        employeeProfileId: "emp-profile-2",
        role: Role.EMPLOYEE,
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  it("15. Invalid state transition rejected (cannot cancel approved request)", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03",
      reason: "Vacation",
    });

    await requestsService.approve(req.id, "user-hr-admin");

    await expect(
      requestsService.cancel(req.id, {
        id: "user-emp-1",
        employeeProfileId: "emp-profile-1",
        role: Role.EMPLOYEE,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it("16. Idempotency prevents duplicate request creation on double tap", async () => {
    const key = "idempotency-key-test-12345";

    const req1 = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03",
      reason: "Vacation",
      idempotencyKey: key,
    });

    const req2 = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03",
      reason: "Vacation",
      idempotencyKey: key,
    });

    expect(req1.id).toBe(req2.id);
    expect(mockRequests.length).toBe(1);
  });

  it("17. Overlapping approved leave request rejected", async () => {
    const req1 = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-05",
      reason: "Vacation 1",
    });

    await requestsService.approve(req1.id, "user-hr-admin");

    // Attempting to submit another request overlapping with 2026-09-03 to 2026-09-07
    await expect(
      requestsService.create("user-emp-1", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-03",
        endDate: "2026-09-07",
        reason: "Vacation 2",
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it("18. Invalid date range (startDate > endDate) rejected", async () => {
    await expect(
      requestsService.create("user-emp-1", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-10",
        endDate: "2026-09-05", // End before start
        reason: "Invalid dates",
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it("19. Inactive or suspended employee cannot create request", async () => {
    await expect(
      requestsService.create("user-inactive", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-01",
        endDate: "2026-09-05",
        reason: "Vacation",
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  it("20. Insufficient leave balance rejected on submission", async () => {
    // emp-profile-2 has only 1 day remaining in mockLeaveBalances
    await expect(
      requestsService.create("user-emp-2", {
        type: RequestType.ANNUAL_LEAVE,
        startDate: "2026-09-01",
        endDate: "2026-09-05", // Requests 5 days
        reason: "Long trip",
      }),
    ).rejects.toThrow(/Insufficient leave balance/);
  });

  it("21. Leave balance deducted accurately upon approval", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-03", // 3 days
      reason: "Vacation",
    });

    await requestsService.approve(req.id, "user-hr-admin");

    const bal = mockLeaveBalances.find((b) => b.employeeId === "emp-profile-1");
    expect(bal.usedDays).toBe(3);
    expect(bal.remainingDays).toBe(18);
  });

  it("22. Attendance record integration marks ON_LEAVE on approved leave", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-02",
      reason: "Vacation",
    });

    await requestsService.approve(req.id, "user-hr-admin");

    expect(mockAttendanceRecords.length).toBe(2);
    expect(mockAttendanceRecords[0].status).toBe(AttendanceStatus.ON_LEAVE);
  });

  it("23. Attendance record integration excuses late arrival upon approved late excuse", async () => {
    // Existing attendance record with LATE status
    mockAttendanceRecords.push({
      id: "att-late-1",
      employeeId: "emp-profile-1",
      date: new Date(Date.UTC(2026, 8, 1)),
      status: AttendanceStatus.LATE,
      lateMinutes: 30,
      notes: null,
    });

    const req = await requestsService.create("user-emp-1", {
      type: RequestType.LATE_EXCUSE,
      startDate: "2026-09-01",
      endDate: "2026-09-01",
      reason: "Bus breakdown",
    });

    await requestsService.approve(req.id, "user-hr-admin");

    const updatedAtt = mockAttendanceRecords.find((a) => a.id === "att-late-1");
    expect(updatedAtt.notes).toContain("Late arrival excused by HR");
  });

  it("24. Audit logs are generated for all state changes", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-02",
      reason: "Vacation",
    });

    await requestsService.approve(req.id, "user-hr-admin");

    const actions = mockAuditLogs.map((l) => l.action);
    expect(actions).toContain(AuditAction.REQUEST_CREATED);
    expect(actions).toContain(AuditAction.REQUEST_APPROVED);
    expect(actions).toContain(AuditAction.LEAVE_BALANCE_UPDATED);
  });

  it("25. Notification failure does not rollback transaction", async () => {
    notificationsService.sendNotification.mockRejectedValueOnce(
      new Error("FCM connection error"),
    );

    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-02",
      reason: "Vacation",
    });

    const approved = await requestsService.approve(req.id, "user-hr-admin");
    expect(approved.status).toBe(RequestStatus.APPROVED);
  });

  it("26. Double approval attempt is rejected with BadRequestException", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-02",
      reason: "Vacation",
    });

    await requestsService.approve(req.id, "user-hr-admin");

    // Attempting second approval
    await expect(
      requestsService.approve(req.id, "user-hr-admin"),
    ).rejects.toThrow(BadRequestException);
  });

  it("27. Double rejection attempt is rejected with BadRequestException", async () => {
    const req = await requestsService.create("user-emp-1", {
      type: RequestType.ANNUAL_LEAVE,
      startDate: "2026-09-01",
      endDate: "2026-09-02",
      reason: "Vacation",
    });

    await requestsService.reject(req.id, "user-hr-admin", {
      reason: "No staffing",
    });

    // Attempting second rejection
    await expect(
      requestsService.reject(req.id, "user-hr-admin", {
        reason: "No staffing 2",
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it("28. Employee can retrieve own leave balance summary", async () => {
    const balances = await requestsService.getMyLeaveBalances(
      "emp-profile-1",
      2026,
    );
    expect(balances.length).toBeGreaterThanOrEqual(1);
    expect(balances[0].employeeId).toBe("emp-profile-1");
  });

  it("29. HR can create and adjust leave balance for employee", async () => {
    const created = await requestsService.createLeaveBalance(
      {
        employeeId: "emp-profile-1",
        leaveType: RequestType.UNPAID_LEAVE,
        year: 2026,
        totalDays: 30,
      },
      "user-hr-admin",
    );

    expect(created.leaveType).toBe(RequestType.UNPAID_LEAVE);
    expect(created.totalDays).toBe(30);

    const adjusted = await requestsService.adjustLeaveBalance(
      created.id,
      { totalDays: 35, reason: "Special allocation" },
      "user-hr-admin",
    );

    expect(adjusted.totalDays).toBe(35);
    expect(
      mockAuditLogs.some((l) => l.action === AuditAction.LEAVE_BALANCE_UPDATED),
    ).toBe(true);
  });

  it("30. Time validation rejects permission with startTime >= endTime on same day", async () => {
    await expect(
      requestsService.create("user-emp-1", {
        type: RequestType.PERMISSION,
        startDate: "2026-09-10",
        endDate: "2026-09-10",
        startTime: "14:00",
        endTime: "12:00", // End before start
        reason: "Errand",
      }),
    ).rejects.toThrow(/Start time must be strictly before end time/);
  });
});
