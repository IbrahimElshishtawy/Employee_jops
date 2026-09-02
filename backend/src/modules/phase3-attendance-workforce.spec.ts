import { Test, TestingModule } from "@nestjs/testing";
import { AttendanceService } from "./attendance/attendance.service";
import { WorkforceService } from "./workforce/workforce.service";
import { AttendanceRepository } from "./attendance/attendance.repository";
import { WorkforceRepository } from "./workforce/workforce.repository";
import { PrismaService } from "../prisma/prisma.service";
import { NotificationsService } from "./notifications/notifications.service";
import { ConfigService } from "@nestjs/config";
import {
  AttendanceStatus,
  CheckInMethod,
  Role,
  UserStatus,
} from "@prisma/client";
import { BadRequestException, ForbiddenException } from "@nestjs/common";

describe("Phase 3 — Attendance & Workforce Operations Complete Specification", () => {
  let attendanceService: AttendanceService;
  let workforceService: WorkforceService;

  const mockWorkplaceHQ = {
    id: "wp-hq",
    name: "Headquarters",
    code: "HQ-01",
    latitude: 24.7136,
    longitude: 46.6753,
    radiusMeters: 100.0,
    isActive: true,
  };

  const mockScheduleStandard = {
    id: "sched-std",
    name: "Standard 09-17",
    startTime: "09:00",
    endTime: "17:00",
    graceMinutesCheckIn: 15,
    graceMinutesCheckOut: 15,
    workingDays: [0, 1, 2, 3, 4, 5, 6], // All days
  };

  const mockScheduleOffToday = {
    id: "sched-off",
    name: "Off Today",
    startTime: "09:00",
    endTime: "17:00",
    graceMinutesCheckIn: 15,
    graceMinutesCheckOut: 15,
    workingDays: [(new Date().getDay() + 4) % 7], // Not today
  };

  const mockUsers: Record<string, any> = {
    "user-valid": {
      id: "user-valid",
      email: "valid.employee@test.com",
      status: UserStatus.ACTIVE,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "emp-valid",
        userId: "user-valid",
        employeeCode: "CW-101",
        firstName: "Karim",
        lastName: "Mahmoud",
        department: "Engineering",
        jobTitle: "Senior Developer",
        isProfileComplete: true,
        workplaceId: "wp-hq",
        workplace: mockWorkplaceHQ,
        scheduleId: "sched-std",
        schedule: mockScheduleStandard,
      },
    },
    "user-off-shift": {
      id: "user-off-shift",
      email: "off.shift@test.com",
      status: UserStatus.ACTIVE,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "emp-off-shift",
        userId: "user-off-shift",
        employeeCode: "CW-102",
        firstName: "Nader",
        lastName: "Samir",
        department: "Support",
        jobTitle: "Agent",
        isProfileComplete: true,
        workplaceId: "wp-hq",
        workplace: mockWorkplaceHQ,
        scheduleId: "sched-off",
        schedule: mockScheduleOffToday,
      },
    },
    "user-suspended": {
      id: "user-suspended",
      email: "suspended@test.com",
      status: UserStatus.SUSPENDED,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "emp-suspended",
        userId: "user-suspended",
        isProfileComplete: true,
        workplace: mockWorkplaceHQ,
        schedule: mockScheduleStandard,
      },
    },
  };

  const recordsDb: Record<string, any> = {};
  const eventsDb: any[] = [];
  const auditLogsDb: any[] = [];

  const mockPrismaService: any = {
    user: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(mockUsers[where.id] || null),
      ),
    },
    employeeProfile: {
      findUnique: jest.fn(({ where }) => {
        const u = Object.values(mockUsers).find(
          (user) => user.employeeProfile?.id === where.id,
        );
        if (u) {
          return Promise.resolve({
            ...u.employeeProfile,
            user: u,
          });
        }
        return Promise.resolve(null);
      }),
      findMany: jest.fn(() =>
        Promise.resolve(Object.values(mockUsers).map((u) => u.employeeProfile)),
      ),
      count: jest.fn(() => Promise.resolve(Object.keys(mockUsers).length)),
    },
    attendanceRecord: {
      findUnique: jest.fn(({ where }) => {
        if (where.requestId && recordsDb[where.requestId]) {
          return Promise.resolve(recordsDb[where.requestId]);
        }
        if (where.employeeId_date) {
          const key = `${where.employeeId_date.employeeId}_${where.employeeId_date.date.toISOString().split("T")[0]}`;
          return Promise.resolve(recordsDb[key] || null);
        }
        return Promise.resolve(null);
      }),
      upsert: jest.fn(({ where, update, create }) => {
        const dateKey = (create?.date || where.employeeId_date.date)
          .toISOString()
          .split("T")[0];
        const key = `${where.employeeId_date.employeeId}_${dateKey}`;
        const existing = recordsDb[key];
        const record = {
          id: existing?.id || `rec-${Object.keys(recordsDb).length + 1}`,
          ...(existing || {}),
          ...create,
          ...update,
        };
        recordsDb[key] = record;
        if (record.requestId) {
          recordsDb[record.requestId] = record;
        }
        return Promise.resolve(record);
      }),
      update: jest.fn(({ where, data }) => {
        const record = Object.values(recordsDb).find((r) => r.id === where.id);
        if (record) {
          Object.assign(record, data);
        }
        return Promise.resolve(record);
      }),
      findMany: jest.fn(() => Promise.resolve(Object.values(recordsDb))),
      count: jest.fn(() => Promise.resolve(Object.keys(recordsDb).length)),
    },
    attendanceEvent: {
      create: jest.fn(({ data }) => {
        const event = { id: `evt-${eventsDb.length + 1}`, ...data };
        eventsDb.push(event);
        return Promise.resolve(event);
      }),
    },
    auditLog: {
      create: jest.fn(({ data }) => {
        const log = { id: `audit-${auditLogsDb.length + 1}`, ...data };
        auditLogsDb.push(log);
        return Promise.resolve(log);
      }),
    },
    request: {
      findMany: jest.fn().mockResolvedValue([]),
    },
    $transaction: jest.fn((cb) => cb(mockPrismaService)),
  };

  const mockNotifications = {
    sendNotification: jest.fn().mockResolvedValue({ id: "notif-1" }),
  };

  const mockConfig = {
    get: jest.fn((key) => {
      if (key === "ATTENDANCE_MAX_GPS_ACCURACY_METERS") return 50.0;
      return null;
    }),
  };

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AttendanceService,
        AttendanceRepository,
        WorkforceService,
        WorkforceRepository,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: NotificationsService, useValue: mockNotifications },
        { provide: ConfigService, useValue: mockConfig },
      ],
    }).compile();

    attendanceService = module.get<AttendanceService>(AttendanceService);
    workforceService = module.get<WorkforceService>(WorkforceService);
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  // 1. Valid Check-in
  it("Scenario 1: Valid Check-in inside geofence records checkIn, event, and audit log", async () => {
    const res = await attendanceService.checkIn("user-valid", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 10.0,
      requestId: "req-001",
      method: CheckInMethod.GPS,
      biometricVerified: true,
    });

    expect(res).toBeDefined();
    expect(res.checkInTime).toBeDefined();
    expect(res.isCheckInWithinGeofence).toBe(true);
    expect(eventsDb.length).toBeGreaterThan(0);
    expect(auditLogsDb.length).toBeGreaterThan(0);
  });

  // 2. Outside Geofence rejection
  it("Scenario 2: Outside Geofence is rejected with OUTSIDE_WORKPLACE", async () => {
    await expect(
      attendanceService.checkIn("user-valid", {
        latitude: 25.1, // ~50km away
        longitude: 46.9,
        accuracy: 15.0,
        requestId: "req-outside-01",
      }),
    ).rejects.toThrow(BadRequestException);
  });

  // 3. Poor GPS Accuracy rejection
  it("Scenario 3: Poor GPS accuracy (>50m) is rejected with GPS_ACCURACY_TOO_LOW", async () => {
    await expect(
      attendanceService.checkIn("user-valid", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 75.0, // Exceeds 50m max
        requestId: "req-poor-accuracy-01",
      }),
    ).rejects.toThrow(BadRequestException);
  });

  // 4. Duplicate Request / Idempotency handling
  it("Scenario 4: Duplicate Request returns existing record without throwing error", async () => {
    const replay = await attendanceService.checkIn("user-valid", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 10.0,
      requestId: "req-001", // Exact same requestId
    });

    expect(replay).toBeDefined();
    expect(replay.requestId).toBe("req-001");
  });

  // 5. Valid Check-out and Duration calculation
  it("Scenario 5: Valid Check-out calculates workDurationMinutes, early/overtime", async () => {
    const res = await attendanceService.checkOut("user-valid", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 12.0,
      requestId: "req-out-001",
    });

    expect(res).toBeDefined();
    expect(res.checkOutTime).toBeDefined();
    expect(res.workDurationMinutes).toBeGreaterThanOrEqual(0);
  });

  // 6. Non-working day / Invalid Shift rejection
  it("Scenario 6: Check-in on a non-working day is rejected with NON_WORKING_DAY", async () => {
    await expect(
      attendanceService.checkIn("user-off-shift", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10.0,
        requestId: "req-off-shift-01",
      }),
    ).rejects.toThrow(BadRequestException);
  });

  // 7. Suspended Employee rejection
  it("Scenario 7: Suspended employee is rejected with EMPLOYEE_SUSPENDED", async () => {
    await expect(
      attendanceService.checkIn("user-suspended", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10.0,
        requestId: "req-suspended-01",
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  // 8. Manual Attendance Correction by HR
  it("Scenario 8: HR Manual Correction updates status, duration, logs event and audit trail", async () => {
    const corrected = await attendanceService.manualAttendanceEntry(
      "hr-admin-user",
      {
        employeeId: "emp-valid",
        date: "2026-09-02",
        status: AttendanceStatus.PRESENT,
        checkInTime: "2026-09-02T09:00:00.000Z",
        checkOutTime: "2026-09-02T18:00:00.000Z",
        reason: "Field mission approved by department head",
      },
    );

    expect(corrected).toBeDefined();
    expect(corrected.isManualEntry).toBe(true);
    expect(corrected.manualCorrectionReason).toBe(
      "Field mission approved by department head",
    );
    expect(corrected.manualCorrectedByUserId).toBe("hr-admin-user");
    expect(corrected.overtimeMinutes).toBe(60); // 18:00 is 1 hour after 17:00
  });

  // 9. Overtime Calculation in Manual Entry & Checkout
  it("Scenario 9: Overtime is calculated correctly when checkout exceeds shift end time", async () => {
    const overtimeRecord = await attendanceService.manualAttendanceEntry(
      "hr-admin-user",
      {
        employeeId: "emp-valid",
        date: "2026-09-01",
        status: AttendanceStatus.PRESENT,
        checkInTime: "2026-09-01T09:00:00.000Z",
        checkOutTime: "2026-09-01T19:30:00.000Z", // 2.5 hours overtime
        reason: "Emergency release overtime",
      },
    );

    expect(overtimeRecord.overtimeMinutes).toBe(150);
  });

  // 10. Workforce Live Status & Attendance Summary
  it("Scenario 10: WorkforceService calculates live presence and aggregated KPIs", async () => {
    const stats = await workforceService.getStatistics({
      startDate: "2026-09-01",
      endDate: "2026-09-30",
    });

    expect(stats.summary).toBeDefined();
    expect(stats.summary.totalRecords).toBeGreaterThan(0);
    expect(stats.summary.totalOvertimeMinutes).toBeGreaterThan(0);
  });
});
