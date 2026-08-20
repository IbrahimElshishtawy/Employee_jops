import { Test, TestingModule } from "@nestjs/testing";
import { AuthService } from "../auth/auth.service";
import { EmployeesService } from "../employees/employees.service";
import { AttendanceService } from "./attendance.service";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { JwtService } from "@nestjs/jwt";
import { ConfigService } from "@nestjs/config";
import { AccountState } from "../../common/enums/account-state.enum";
import { UserStatus, Role, AttendanceStatus } from "@prisma/client";
import {
  BadRequestException,
  ForbiddenException,
  UnauthorizedException,
} from "@nestjs/common";

describe("Employee Core — 10 Mandatory E2E Scenarios", () => {
  let authService: AuthService;
  let employeesService: EmployeesService;
  let attendanceService: AttendanceService;
  let prisma: PrismaService;

  // Mock In-Memory Store
  const mockWorkplace = {
    id: "wp-hq-01",
    name: "CyberWise Headquarters",
    code: "HQ-MAIN",
    latitude: 24.7136,
    longitude: 46.6753,
    radiusMeters: 100,
    isActive: true,
  };

  const mockSchedule = {
    id: "sched-01",
    name: "Standard Working Hours",
    startTime: "09:00",
    endTime: "17:00",
    graceMinutesCheckIn: 15,
    graceMinutesCheckOut: 15,
    workingDays: [0, 1, 2, 3, 4, 5, 6],
    isDefault: true,
  };

  const mockUsers: Record<string, any> = {
    "user-new": {
      id: "user-new",
      email: "employee.new@example.test",
      googleId: "google-new-id",
      status: UserStatus.ACTIVE,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "prof-new",
        userId: "user-new",
        employeeCode: "CW-1002",
        firstName: "New",
        lastName: "Joiner",
        isProfileComplete: false,
        workplaceId: null,
        scheduleId: null,
      },
    },
    "user-active": {
      id: "user-active",
      email: "employee.active@example.test",
      googleId: "google-active-id",
      status: UserStatus.ACTIVE,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "prof-active",
        userId: "user-active",
        employeeCode: "CW-1001",
        firstName: "Tariq",
        lastName: "Zaid",
        nationalId: "1000001001",
        phone: "+966500001001",
        jobTitle: "Senior Software Engineer",
        department: "Engineering",
        isProfileComplete: true,
        workplaceId: "wp-hq-01",
        workplace: mockWorkplace,
        scheduleId: "sched-01",
        schedule: mockSchedule,
      },
    },
    "user-suspended": {
      id: "user-suspended",
      email: "employee.suspended@example.test",
      googleId: "google-suspended-id",
      status: UserStatus.SUSPENDED,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "prof-suspended",
        userId: "user-suspended",
        isProfileComplete: true,
      },
    },
    "user-noworkplace": {
      id: "user-noworkplace",
      email: "employee.noworkplace@example.test",
      googleId: "google-nowp-id",
      status: UserStatus.ACTIVE,
      role: Role.EMPLOYEE,
      employeeProfile: {
        id: "prof-nowp",
        userId: "user-noworkplace",
        isProfileComplete: true,
        workplaceId: null,
        workplace: null,
        scheduleId: "sched-01",
        schedule: mockSchedule,
      },
    },
  };

  const attendanceRecords: Record<string, any> = {};

  const mockPrismaService: any = {
    user: {
      findFirst: jest.fn(({ where }) => {
        const email = where?.OR?.[0]?.email;
        const googleId = where?.OR?.[1]?.googleId;
        const user = Object.values(mockUsers).find(
          (u) => u.email === email || u.googleId === googleId,
        );
        return Promise.resolve(user || null);
      }),
      findUnique: jest.fn(({ where }) => {
        return Promise.resolve(mockUsers[where.id] || null);
      }),
      update: jest.fn(({ where, data }) => {
        if (mockUsers[where.id]) {
          Object.assign(mockUsers[where.id], data);
        }
        return Promise.resolve(mockUsers[where.id]);
      }),
    },
    employeeProfile: {
      findFirst: jest.fn().mockResolvedValue(null),
      findUnique: jest.fn(({ where }) => {
        const found = Object.values(mockUsers).find(
          (u) => u.employeeProfile?.id === where.id,
        );
        return Promise.resolve(found?.employeeProfile || null);
      }),
      upsert: jest.fn(({ where, update, create }) => {
        const user = mockUsers[where.userId];
        if (user) {
          user.employeeProfile = {
            ...user.employeeProfile,
            ...update,
            isProfileComplete: true,
            workplace: mockWorkplace,
            schedule: mockSchedule,
          };
          return Promise.resolve(user.employeeProfile);
        }
        return Promise.resolve(create);
      }),
    },
    workplace: {
      findUnique: jest.fn(({ where }) => {
        if (where.id === "wp-hq-01") return Promise.resolve(mockWorkplace);
        return Promise.resolve(null);
      }),
    },
    attendanceRecord: {
      findUnique: jest.fn(({ where }) => {
        if (where.requestId && attendanceRecords[where.requestId]) {
          return Promise.resolve(attendanceRecords[where.requestId]);
        }
        if (where.employeeId_date) {
          const key = `${where.employeeId_date.employeeId}`;
          return Promise.resolve(attendanceRecords[key] || null);
        }
        return Promise.resolve(null);
      }),
      upsert: jest.fn(({ where, update, create }) => {
        const key = `${where.employeeId_date.employeeId}`;
        const record = {
          id: "rec-001",
          ...create,
          ...update,
        };
        attendanceRecords[key] = record;
        if (record.requestId) {
          attendanceRecords[record.requestId] = record;
        }
        return Promise.resolve(record);
      }),
      update: jest.fn(({ where, data }) => {
        const record = Object.values(attendanceRecords).find(
          (r) => r.id === where.id,
        );
        if (record) {
          Object.assign(record, data);
        }
        return Promise.resolve(record);
      }),
    },
    refreshToken: {
      create: jest.fn().mockResolvedValue({ id: "tok-01" }),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    attendanceEvent: {
      create: jest.fn().mockResolvedValue({ id: "evt-01" }),
    },
    auditLog: {
      create: jest.fn().mockResolvedValue({ id: "audit-01" }),
    },
    $transaction: jest.fn((callback) => callback(mockPrismaService)),
  };

  const mockJwtService = {
    signAsync: jest.fn().mockResolvedValue("mock_jwt_access_token_12345"),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      if (key === "jwt.accessSecret") return "test_secret_12345";
      if (key === "jwt.accessExpiration") return "15m";
      return null;
    }),
  };

  const mockNotificationsService = {
    sendNotification: jest.fn().mockResolvedValue({ id: "notif-01" }),
  };

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        EmployeesService,
        AttendanceService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: NotificationsService, useValue: mockNotificationsService },
      ],
    }).compile();

    authService = module.get<AuthService>(AuthService);
    employeesService = module.get<EmployeesService>(EmployeesService);
    attendanceService = module.get<AttendanceService>(AttendanceService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  // ============================================================
  // Scenario 1: New Employee Google Login -> Profile Incomplete -> Complete Profile -> Active
  // ============================================================
  it("Scenario 1: New Employee Google Login -> PROFILE_INCOMPLETE -> Complete Profile -> ACTIVE", async () => {
    // 1. Google Login with new employee test token
    const loginRes = await authService.googleLogin({
      idToken: "test-google-token:employee.new@example.test:google-new-id",
    });

    expect(loginRes.accessToken).toBeDefined();
    expect(loginRes.user.accountState).toBe(AccountState.PROFILE_INCOMPLETE);
    expect(loginRes.user.isProfileComplete).toBe(false);

    // 2. Complete Profile
    const completeRes = await employeesService.completeProfile("user-new", {
      firstName: "New",
      lastName: "Joiner",
      nationalId: "1098765432",
      phone: "+966509998877",
      jobTitle: "Software Engineer",
      department: "Engineering",
      workplaceId: "wp-hq-01",
    });

    expect(completeRes.accountState).toBe(AccountState.ACTIVE_EMPLOYEE);
    expect(completeRes.profile.isProfileComplete).toBe(true);
    // Verify nationalId is masked
    expect(completeRes.profile.nationalId).toBe("******5432");
  });

  // ============================================================
  // Scenario 2: Existing Employee Google Login -> Active
  // ============================================================
  it("Scenario 2: Existing Employee Google Login -> ACTIVE_EMPLOYEE", async () => {
    const loginRes = await authService.googleLogin({
      idToken:
        "test-google-token:employee.active@example.test:google-active-id",
    });

    expect(loginRes.accessToken).toBeDefined();
    expect(loginRes.user.accountState).toBe(AccountState.ACTIVE_EMPLOYEE);
    expect(loginRes.user.isProfileComplete).toBe(true);
  });

  // ============================================================
  // Scenario 3: Suspended Employee Google Login -> Access Denied
  // ============================================================
  it("Scenario 3: Suspended Employee -> Access Denied (ForbiddenException)", async () => {
    await expect(
      authService.googleLogin({
        idToken:
          "test-google-token:employee.suspended@example.test:google-suspended-id",
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  // ============================================================
  // Scenario 4: Employee without Workplace -> Attendance Unavailable
  // ============================================================
  it("Scenario 4: Employee without Workplace -> WORKPLACE_NOT_ASSIGNED error", async () => {
    await expect(
      attendanceService.checkIn("user-noworkplace", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  // ============================================================
  // Scenario 5: Employee outside workplace -> Geofence check rejects check-in
  // ============================================================
  it("Scenario 5: Employee outside workplace boundary -> OUTSIDE_WORKPLACE rejection", async () => {
    // 5 km away from HQ
    await expect(
      attendanceService.checkIn("user-active", {
        latitude: 24.75,
        longitude: 46.72,
        accuracy: 15,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  // ============================================================
  // Scenario 6: Employee inside workplace & on schedule -> Check-in accepted
  // ============================================================
  it("Scenario 6: Employee inside workplace -> Check-in accepted successfully", async () => {
    const record = await attendanceService.checkIn("user-active", {
      latitude: 24.7136, // Exact HQ coordinates
      longitude: 46.6753,
      accuracy: 10,
      requestId: "req-checkin-001",
      biometricVerified: true,
    });

    expect(record).toBeDefined();
    expect(record.checkInTime).toBeDefined();
    expect(record.isCheckInWithinGeofence).toBe(true);
    expect([AttendanceStatus.PRESENT, AttendanceStatus.LATE]).toContain(
      record.status,
    );
  });

  // ============================================================
  // Scenario 7: Duplicate check-in on same day -> Rejected safely
  // ============================================================
  it("Scenario 7: Duplicate check-in attempt -> ALREADY_CHECKED_IN rejection", async () => {
    await expect(
      attendanceService.checkIn("user-active", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  // ============================================================
  // Scenario 8: Valid check-out -> Success with duration computation
  // ============================================================
  it("Scenario 8: Valid check-out -> Success and work duration recorded", async () => {
    const checkoutRecord = await attendanceService.checkOut("user-active", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 10,
      requestId: "req-checkout-001",
      biometricVerified: true,
    });

    expect(checkoutRecord).toBeDefined();
    expect(checkoutRecord.checkOutTime).toBeDefined();
    expect(checkoutRecord.workDurationMinutes).toBeGreaterThanOrEqual(0);
  });

  // ============================================================
  // Scenario 9: Poor GPS accuracy -> Rejected with GPS_ACCURACY_TOO_LOW
  // ============================================================
  it("Scenario 9: Poor GPS accuracy (> 50m) -> GPS_ACCURACY_TOO_LOW rejection", async () => {
    await expect(
      attendanceService.checkOut("user-active", {
        latitude: 24.7136,
        longitude: 46.6753,
        accuracy: 85, // Exceeds 50m limit
      }),
    ).rejects.toThrow(BadRequestException);
  });

  // ============================================================
  // Scenario 10: Suspicious device signals -> Security policy evaluated & recorded
  // ============================================================
  it("Scenario 10: Suspicious device telemetry (Mock Location / Jailbreak) evaluated and audited", async () => {
    delete attendanceRecords["prof-active"]; // Reset for clean test

    const record = await attendanceService.checkIn("user-active", {
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 12,
      isMockLocation: true, // Suspicious
      isVpn: true,
    });

    expect(record.isSuspicious).toBe(true);
    expect((record.deviceSignals as any).isMockLocation).toBe(true);
  });
});
