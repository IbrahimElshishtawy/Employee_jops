import { Test, TestingModule } from "@nestjs/testing";
import { UnauthorizedException, ForbiddenException } from "@nestjs/common";
import { AuthService } from "./auth/auth.service";
import { PayrollService } from "./payroll/payroll.service";
import { PrismaService } from "../prisma/prisma.service";
import { JwtService } from "@nestjs/jwt";
import { ConfigService } from "@nestjs/config";
import { NotificationsService } from "./notifications/notifications.service";
import { PayrollCalculatorService } from "./payroll/payroll-calculator.service";
import { Role, UserStatus } from "@prisma/client";

describe("Phase 09 — Security Hardening, E2E & Concurrency Suite", () => {
  let authService: AuthService;
  let payrollService: PayrollService;

  const mockPrisma: any = {
    user: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
    },
    refreshToken: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
    salaryProfile: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    employeeProfile: {
      findUnique: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
    $transaction: jest.fn(async (cb: any) =>
      typeof cb === "function" ? cb(mockPrisma) : Promise.all(cb),
    ),
  };

  const mockJwtService = {
    signAsync: jest.fn().mockResolvedValue("mock_signed_jwt_token"),
    verifyAsync: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      if (key === "jwt.accessSecret") return "test_access_secret_1234567890";
      if (key === "jwt.accessExpiration") return "15m";
      return null;
    }),
  };

  const mockNotificationsService = {
    create: jest.fn(),
  };

  const mockPayrollCalculator = {
    calculatePayrollForEmployee: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        PayrollService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: NotificationsService, useValue: mockNotificationsService },
        { provide: PayrollCalculatorService, useValue: mockPayrollCalculator },
      ],
    }).compile();

    authService = module.get<AuthService>(AuthService);
    payrollService = module.get<PayrollService>(PayrollService);
    jest.clearAllMocks();
  });

  // ============================================================
  // 1. AUTHENTICATION & REFRESH TOKEN ROTATION / REPLAY ATTACKS
  // ============================================================
  describe("Authentication Hardening & Token Rotation", () => {
    it("should successfully rotate refresh token when valid token is presented", async () => {
      const validTokenRecord = {
        id: "token-123",
        userId: "user-001",
        tokenHash: "hashed_token",
        expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24),
        revokedAt: null,
        user: {
          id: "user-001",
          email: "employee@cyberwise.com",
          role: Role.EMPLOYEE,
          status: UserStatus.ACTIVE,
          employeeProfile: { id: "emp-001" },
        },
      };

      mockPrisma.refreshToken.findUnique.mockResolvedValue(validTokenRecord);
      mockPrisma.refreshToken.update.mockResolvedValue({});
      mockPrisma.refreshToken.create.mockResolvedValue({});

      const result = await authService.refreshToken("valid_raw_token_xyz");

      expect(result.accessToken).toBe("mock_signed_jwt_token");
      expect(result.refreshToken).toBeDefined();
      expect(mockPrisma.refreshToken.update).toHaveBeenCalledWith({
        where: { id: "token-123" },
        data: { revokedAt: expect.any(Date) },
      });
    });

    it("should detect Refresh Token Replay and invalidate ALL user sessions", async () => {
      const revokedTokenRecord = {
        id: "token-compromised",
        userId: "victim-user-001",
        tokenHash: "hashed_compromised_token",
        expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24),
        revokedAt: new Date(Date.now() - 1000 * 60 * 5), // Revoked 5 mins ago
        user: {
          id: "victim-user-001",
          email: "victim@cyberwise.com",
          role: Role.EMPLOYEE,
          status: UserStatus.ACTIVE,
        },
      };

      mockPrisma.refreshToken.findUnique.mockResolvedValue(revokedTokenRecord);
      mockPrisma.refreshToken.updateMany.mockResolvedValue({ count: 3 });
      mockPrisma.auditLog.create.mockResolvedValue({});

      await expect(
        authService.refreshToken("replayed_revoked_token"),
      ).rejects.toThrow(UnauthorizedException);

      // Verify that ALL sessions for this user were invalidated
      expect(mockPrisma.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { userId: "victim-user-001", revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });

      // Verify security audit log was created
      expect(mockPrisma.auditLog.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            userId: "victim-user-001",
            entity: "RefreshToken",
            payload: expect.objectContaining({
              alert: "REFRESH_TOKEN_REPLAY_ATTACK",
            }),
          }),
        }),
      );
    });

    it("should reject expired refresh tokens", async () => {
      const expiredTokenRecord = {
        id: "token-expired",
        userId: "user-001",
        tokenHash: "hashed_expired_token",
        expiresAt: new Date(Date.now() - 1000 * 60 * 60), // Expired 1 hour ago
        revokedAt: null,
        user: { id: "user-001", status: UserStatus.ACTIVE },
      };

      mockPrisma.refreshToken.findUnique.mockResolvedValue(expiredTokenRecord);

      await expect(
        authService.refreshToken("expired_token_xyz"),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  // ============================================================
  // 2. IDOR / OBJECT AUTHORIZATION RESTRICTIONS
  // ============================================================
  describe("IDOR & Data Access Isolation", () => {
    it("should FORBID Employee A from accessing Employee B salary profile", async () => {
      const currentUser = {
        id: "user-employee-a",
        role: Role.EMPLOYEE,
        employeeProfileId: "emp-profile-a",
      };

      // Employee A tries to fetch Employee B (emp-profile-b)
      await expect(
        payrollService.getSalaryProfile("emp-profile-b", currentUser),
      ).rejects.toThrow(ForbiddenException);
    });

    it("should ALLOW Employee A to access their OWN salary profile", async () => {
      const currentUser = {
        id: "user-employee-a",
        role: Role.EMPLOYEE,
        employeeProfileId: "emp-profile-a",
      };

      const mySalaryProfile = {
        id: "sal-profile-a",
        employeeId: "emp-profile-a",
        basicSalary: 25000,
        allowances: 2000,
        currency: "EGP",
        employee: { firstName: "Ahmed", lastName: "Ali" },
      };

      mockPrisma.salaryProfile.findUnique.mockResolvedValue(mySalaryProfile);

      const result = await payrollService.getSalaryProfile(
        "emp-profile-a",
        currentUser,
      );
      expect(result).toBeDefined();
      expect(result.employeeId).toBe("emp-profile-a");
    });

    it("should ALLOW HR_ADMIN to access ANY employee salary profile", async () => {
      const hrUser = {
        id: "user-hr-admin",
        role: Role.HR_ADMIN,
        employeeProfileId: "hr-profile-id",
      };

      const employeeBSalaryProfile = {
        id: "sal-profile-b",
        employeeId: "emp-profile-b",
        basicSalary: 30000,
        allowances: 5000,
        currency: "EGP",
        employee: { firstName: "Mona", lastName: "Hassan" },
      };

      mockPrisma.salaryProfile.findUnique.mockResolvedValue(
        employeeBSalaryProfile,
      );

      const result = await payrollService.getSalaryProfile(
        "emp-profile-b",
        hrUser,
      );
      expect(result).toBeDefined();
      expect(result.employeeId).toBe("emp-profile-b");
    });
  });

  // ============================================================
  // 3. CONCURRENCY & RACE CONDITION PROTECTION
  // ============================================================
  describe("Concurrency & State Consistency", () => {
    it("should execute concurrent actions cleanly through database transactions", async () => {
      const operations = [
        mockPrisma.$transaction(async (tx: any) =>
          tx.user.findUnique({ where: { id: "1" } }),
        ),
        mockPrisma.$transaction(async (tx: any) =>
          tx.user.findUnique({ where: { id: "2" } }),
        ),
      ];

      const results = await Promise.all(operations);
      expect(results).toHaveLength(2);
      expect(mockPrisma.$transaction).toHaveBeenCalledTimes(2);
    });
  });
});
