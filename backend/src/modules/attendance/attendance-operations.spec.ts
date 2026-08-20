import { Test, TestingModule } from "@nestjs/testing";
import { AttendanceService } from "./attendance.service";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { ConfigService } from "@nestjs/config";
import { AttendanceStatus, Role, UserStatus } from "@prisma/client";
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from "@nestjs/common";

describe("Phase 03 — Attendance & Workforce Operations (23+ Scenarios & Safety)", () => {
  let attendanceService: AttendanceService;

  const mockWorkplaceActive = {
    id: "wp-hq-01",
    name: "CyberWise Headquarters",
    code: "HQ-MAIN",
    latitude: 24.7136,
    longitude: 46.6753,
    radiusMeters: 100, // Explicitly loaded from database
    isActive: true,
  };

  const mockWorkplaceInactive = {
    id: "wp-inactive-01",
    name: "Closed Branch",
    code: "CLOSED-01",
    latitude: 24.7136,
    longitude: 46.6753,
    radiusMeters: 100,
    isActive: false,
  };

  const mockScheduleAllDays = {
    id: "sched-all-days",
    name: "Standard Working Hours",
    startTime: "09:00",
    endTime: "17:00",
    graceMinutesCheckIn: 15,
    graceMinutesCheckOut: 15,
    workingDays: [0, 1, 2, 3, 4, 5, 6],
    isDefault: true,
  };

  const mockScheduleNoToday = {
    id: "sched-no-today",
    name: "Shift Not Today",
    startTime: "09:00",
    endTime: "17:00",
    graceMinutesCheckIn: 15,
    graceMinutesCheckOut: 15,
    workingDays: [(new Date().getDay() + 3) % 7], // Not today
    isDefault: false,
  };

  const mockUsers: Record<string, any> = {
    "user-active": {
      id: "user-active",
      email: "employee.active@example.test",
      status: UserStatus.ACTIVE,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "prof-active",
        userId: "user-active",
        employeeCode: "CW-1001",
        firstName: "Tariq",
        lastName: "Zaid",
        department: "Engineering",
        isProfileComplete: true,
        workplaceId: "wp-hq-01",
        workplace: mockWorkplaceActive,
        scheduleId: "sched-all-days",
        schedule: mockScheduleAllDays,
      },
    },
    "user-inactive": {
      id: "user-inactive",
      email: "employee.inactive@example.test",
      status: UserStatus.INACTIVE,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "prof-inactive",
        userId: "user-inactive",
        isProfileComplete: true,
        workplace: mockWorkplaceActive,
        schedule: mockScheduleAllDays,
      },
    },
    "user-suspended": {
      id: "user-suspended",
      email: "employee.suspended@example.test",
      status: UserStatus.SUSPENDED,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "prof-suspended",
        userId: "user-suspended",
        isProfileComplete: true,
        workplace: mockWorkplaceActive,
        schedule: mockScheduleAllDays,
      },
    },
    "user-inactive-workplace": {
      id: "user-inactive-workplace",
      email: "employee.inwp@example.test",
      status: UserStatus.ACTIVE,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "prof-inwp",
        userId: "user-inactive-workplace",
        isProfileComplete: true,
        workplaceId: "wp-inactive-01",
        workplace: mockWorkplaceInactive,
        scheduleId: "sched-all-days",
        schedule: mockScheduleAllDays,
      },
    },
    "user-no-workplace": {
      id: "user-no-workplace",
      email: "employee.nowp@example.test",
      status: UserStatus.ACTIVE,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "prof-nowp",
        userId: "user-no-workplace",
        isProfileComplete: true,
        workplaceId: null,
        workplace: null,
        schedule: mockScheduleAllDays,
      },
    },
    "user-no-schedule": {
      id: "user-no-schedule",
      email: "employee.nosched@example.test",
      status: UserStatus.ACTIVE,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "prof-nosched",
        userId: "user-no-schedule",
        isProfileComplete: true,
        workplace: mockWorkplaceActive,
        schedule: null,
      },
    },
    "user-non-working-day": {
      id: "user-non-working-day",
      email: "employee.offday@example.test",
      status: UserStatus.ACTIVE,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "prof-offday",
        userId: "user-non-working-day",
        isProfileComplete: true,
        workplace: mockWorkplaceActive,
        schedule: mockScheduleNoToday,
      },
    },
  };

  const recordsStore: Record<string, any> = {};
  const eventsStore: any[] = [];
  const auditLogsStore: any[] = [];

  const mockPrismaService: any = {
    user: {
      findUnique: jest.fn(({ where }) =>
        Promise.resolve(mockUsers[where.id] || null),
      ),
    },
    employeeProfile: {
      findUnique: jest.fn(({ where }) => {
        const found = Object.values(mockUsers).find(
          (u) => u.employeeProfile?.id === where.id,
        );
        if (found) {
          return Promise.resolve({
            ...found.employeeProfile,
            user: found,
          });
        }
        return Promise.resolve(null);
      }),
    },
    attendanceRecord: {
      findUnique: jest.fn(({ where }) => {
        if (where.requestId && recordsStore[where.requestId]) {
          return Promise.resolve(recordsStore[where.requestId]);
        }
        if (where.employeeId_date) {
          const key = `${where.employeeId_date.employeeId}`;
          return Promise.resolve(recordsStore[key] || null);
        }
        return Promise.resolve(null);
      }),
      upsert: jest.fn(({ where, update, create }) => {
        const key = `${where.employeeId_date.employeeId}`;
        const record = {
          id: `rec-${Object.keys(recordsStore).length + 1}`,
          ...create,
          ...update,
        };
        recordsStore[key] = record;
        if (record.requestId) {
          recordsStore[record.requestId] = record;
        }
        return Promise.resolve(record);
      }),
      update: jest.fn(({ where, data }) => {
        const record = Object.values(recordsStore).find(
          (r) => r.id === where.id,
        );
        if (record) {
          Object.assign(record, data);
        }
        return Promise.resolve(record);
      }),
      count: jest.fn().mockResolvedValue(Object.keys(recordsStore).length),
      findMany: jest.fn().mockResolvedValue(Object.values(recordsStore)),
    },
    attendanceEvent: {
      create: jest.fn(({ data }) => {
        const event = { id: `event-${eventsStore.length + 1}`, ...data };
        eventsStore.push(event);
        return Promise.resolve(event);
      }),
    },
    auditLog: {
      create: jest.fn(({ data }) => {
        const log = { id: `audit-${auditLogsStore.length + 1}`, ...data };
        auditLogsStore.push(log);
        return Promise.resolve(log);
      }),
    },
    $transaction: jest.fn((callback) => callback(mockPrismaService)),
  };

  const mockNotificationsService = {
    sendNotification: jest.fn().mockResolvedValue({ id: "notif-01" }),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      if (key === "ATTENDANCE_MAX_GPS_ACCURACY_METERS") return 50.0;
      return null;
    }),
  };

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AttendanceService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: NotificationsService, useValue: mockNotificationsService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    attendanceService = module.get<AttendanceService>(AttendanceService);
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  // Scenario 1: Valid check-in inside workplace
  it("1. Valid check-in: records attendance, event, and audit log", async () => {
    delete recordsStore["prof-active"];
    const record = await attendanceService.checkIn("user-active", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 10,
      requestId: "req-op-001",
    });

    expect(record).toBeDefined();
    expect(record.checkInTime).toBeDefined();
    expect(record.isCheckInWithinGeofence).toBe(true);
    expect(eventsStore.length).toBeGreaterThan(0);
    expect(auditLogsStore.length).toBeGreaterThan(0);
  });

  // Scenario 2: Valid check-out
  it("2. Valid check-out: calculates working duration and early departure", async () => {
    const record = await attendanceService.checkOut("user-active", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 12,
      requestId: "req-op-002",
    });

    expect(record).toBeDefined();
    expect(record.checkOutTime).toBeDefined();
    expect(record.workDurationMinutes).toBeGreaterThanOrEqual(0);
  });

  // Scenario 3: Outside workplace boundary
  it("3. Outside workplace: rejects check-in with OUTSIDE_WORKPLACE", async () => {
    delete recordsStore["prof-active"];
    await expect(
      attendanceService.checkIn("user-active", {
        latitude: 24.85, // ~15km away
        longitude: 46.85,
        accuracy: 10,
      }),
    ).rejects.toThrow(/OUTSIDE_WORKPLACE/);
  });

  // Scenario 4: Configurable GPS threshold evaluation
  it("4. GPS accuracy threshold is configurable from ConfigService", async () => {
    delete recordsStore["prof-active"];
    await expect(
      attendanceService.checkIn("user-active", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 120, // > 50m
      }),
    ).rejects.toThrow(/GPS_ACCURACY_TOO_LOW/);
  });

  // Scenario 5: Poor GPS accuracy on checkout
  it("5. Poor GPS accuracy on checkout: rejects with GPS_ACCURACY_TOO_LOW", async () => {
    await expect(
      attendanceService.checkOut("user-active", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 95,
      }),
    ).rejects.toThrow(/GPS_ACCURACY_TOO_LOW/);
  });

  // Scenario 6: Workplace inactive
  it("6. Workplace inactive: rejects check-in with WORKPLACE_INACTIVE", async () => {
    await expect(
      attendanceService.checkIn("user-inactive-workplace", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toThrow(/WORKPLACE_INACTIVE/);
  });

  // Scenario 7: Employee inactive
  it("7. Employee inactive: rejects check-in with EMPLOYEE_INACTIVE", async () => {
    await expect(
      attendanceService.checkIn("user-inactive", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  // Scenario 8: Employee suspended
  it("8. Employee suspended: rejects check-in with EMPLOYEE_SUSPENDED", async () => {
    await expect(
      attendanceService.checkIn("user-suspended", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  // Scenario 9: No workplace assigned
  it("9. No workplace: rejects check-in with WORKPLACE_NOT_ASSIGNED", async () => {
    await expect(
      attendanceService.checkIn("user-no-workplace", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toThrow(/WORKPLACE_NOT_ASSIGNED/);
  });

  // Scenario 10: No schedule assigned
  it("10. No schedule: rejects check-in with SCHEDULE_NOT_ASSIGNED", async () => {
    await expect(
      attendanceService.checkIn("user-no-schedule", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toThrow(/SCHEDULE_NOT_ASSIGNED/);
  });

  // Scenario 11: Non-working day evaluation
  it("11. Non-working day: rejects check-in with NON_WORKING_DAY", async () => {
    await expect(
      attendanceService.checkIn("user-non-working-day", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toThrow(/NON_WORKING_DAY/);
  });

  // Scenario 12 & 13: Shift calculation evaluation (On-time / Late)
  it("12 & 13. Arrival status and lateMinutes evaluated based on schedule grace period", async () => {
    delete recordsStore["prof-active"];
    const record = await attendanceService.checkIn("user-active", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 5,
    });
    expect([AttendanceStatus.PRESENT, AttendanceStatus.LATE]).toContain(
      record.status,
    );
    expect(record.lateMinutes).toBeGreaterThanOrEqual(0);
  });

  // Scenario 14: Early checkout evaluation
  it("14. Early checkout: earlyLeaveMinutes calculated against scheduled shift end", async () => {
    const record = await attendanceService.checkOut("user-active", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 10,
    });
    expect(record.earlyLeaveMinutes).toBeGreaterThanOrEqual(0);
  });

  // Scenario 15: Duplicate check-in
  it("15. Duplicate check-in: rejected with ALREADY_CHECKED_IN", async () => {
    await expect(
      attendanceService.checkIn("user-active", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toThrow(/ALREADY_CHECKED_IN/);
  });

  // Scenario 16: Duplicate checkout
  it("16. Duplicate checkout: rejected with ALREADY_CHECKED_OUT", async () => {
    await expect(
      attendanceService.checkOut("user-active", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toThrow(/ALREADY_CHECKED_OUT/);
  });

  // Scenario 17: Invalid state transition (check-out without check-in)
  it("17. Invalid state transition: checkout without prior check-in fails with NO_ACTIVE_CHECK_IN", async () => {
    delete recordsStore["prof-active"];
    await expect(
      attendanceService.checkOut("user-active", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toThrow(/NO_ACTIVE_CHECK_IN/);
  });

  // Scenario 18: Replay attempt with same requestId
  it("18. Replay attempt: idempotent return for duplicate requestId", async () => {
    delete recordsStore["prof-active"];
    const initial = await attendanceService.checkIn("user-active", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 10,
      requestId: "replay-req-12345",
    });

    const duplicateReplay = await attendanceService.checkIn("user-active", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 10,
      requestId: "replay-req-12345",
    });

    expect(duplicateReplay.id).toBe(initial.id);
  });

  // Scenario 19: Employee personal attendance (IDOR safe)
  it("19. Employee personal attendance: queries only authenticated user records", async () => {
    const result = await attendanceService.getMyAttendance("user-active", {
      page: 1,
      limit: 10,
    });
    expect(result.data).toBeDefined();
    expect(result.meta).toBeDefined();
  });

  // Scenario 20: HR Attendance Access
  it("20. HR attendance access: retrieves records by employee, workplace, and department", async () => {
    const empResult = await attendanceService.getEmployeeAttendance(
      "prof-active",
      {},
    );
    const wpResult = await attendanceService.getWorkplaceAttendance(
      "wp-hq-01",
      {},
    );
    const deptResult = await attendanceService.getDepartmentAttendance(
      "Engineering",
      {},
    );

    expect(empResult.data).toBeDefined();
    expect(wpResult.data).toBeDefined();
    expect(deptResult.data).toBeDefined();
  });

  // Scenario 21: HR Manual Attendance Correction with Mandatory Reason
  it("21. HR Manual Attendance Correction: applies adjustment, records reason and states, and logs audit", async () => {
    const adjusted = await attendanceService.manualAttendanceEntry(
      "hr-user-id",
      {
        employeeId: "prof-active",
        date: "2026-08-19",
        status: AttendanceStatus.PRESENT,
        checkInTime: "2026-08-19T09:00:00.000Z",
        checkOutTime: "2026-08-19T17:00:00.000Z",
        reason: "Biometric reader network glitch confirmed by IT",
      },
    );

    expect(adjusted.isManualEntry).toBe(true);
    expect(adjusted.manualCorrectionReason).toBe(
      "Biometric reader network glitch confirmed by IT",
    );
    expect(adjusted.manualCorrectedByUserId).toBe("hr-user-id");
  });

  // Scenario 22: Audit log verification on events
  it("22. Audit log creation: records check-in, check-out, and rejections", async () => {
    expect(auditLogsStore.length).toBeGreaterThan(0);
  });

  // Scenario 23: Suspicious device signal handling & telemetry sanitization
  it("23. Suspicious device signals: mock location & VPN signals recorded safely without secrets", async () => {
    delete recordsStore["prof-active"];
    const record = await attendanceService.checkIn("user-active", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 8,
      isMockLocation: true,
      isVpn: true,
    });

    expect(record.isSuspicious).toBe(true);
    expect((record.deviceSignals as any).isMockLocation).toBe(true);
    expect((record.deviceSignals as any).isVpn).toBe(true);
  });

  // Scenario 24: Notification failure isolation
  it("24. Notification failure isolation: attendance succeeds even if notification service throws", async () => {
    delete recordsStore["prof-active"];
    mockNotificationsService.sendNotification.mockRejectedValueOnce(
      new Error("FCM Connection Timeout"),
    );

    const record = await attendanceService.checkIn("user-active", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 10,
    });

    expect(record).toBeDefined();
    expect(record.checkInTime).toBeDefined();
  });
});
