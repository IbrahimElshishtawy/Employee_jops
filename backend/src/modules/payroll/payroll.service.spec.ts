import { Test, TestingModule } from "@nestjs/testing";
import { PayrollService } from "./payroll.service";
import { PayrollCalculatorService } from "./payroll-calculator.service";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { BadRequestException, ForbiddenException } from "@nestjs/common";
import {
  Role,
  UserStatus,
  AdvanceStatus,
  InstallmentStatus,
  PayrollPeriodStatus,
  PayrollLineItemType,
  DeductionType,
  AttendanceStatus,
  RequestType,
  Prisma,
} from "@prisma/client";

describe("PayrollService & PayrollCalculatorService (Phase 05 Full Test Suite)", () => {
  let payrollService: PayrollService;
  let payrollCalculator: PayrollCalculatorService;

  const mockEmployeeId = "emp-test-uuid-1";
  const mockUserId = "user-test-uuid-1";
  const mockApproverId = "hr-admin-uuid-1";

  const mockPrismaService: any = {
    user: {
      findUnique: jest.fn(),
    },
    employeeProfile: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
    },
    salaryProfile: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    salaryHistory: {
      findMany: jest.fn(),
      create: jest.fn(),
    },
    financialAdvance: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
    },
    advanceInstallment: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    financialDeduction: {
      findMany: jest.fn(),
      create: jest.fn(),
      count: jest.fn(),
    },
    payrollPeriod: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
    },
    payrollRecord: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      delete: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      count: jest.fn(),
    },
    payrollLineItem: {
      findMany: jest.fn(),
      create: jest.fn(),
      deleteMany: jest.fn(),
    },
    payrollAdjustment: {
      create: jest.fn(),
    },
    attendanceRecord: {
      findMany: jest.fn(),
    },
    request: {
      findMany: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
    $transaction: jest.fn((cb) => cb(mockPrismaService)),
  };

  const mockNotificationsService = {
    sendNotification: jest.fn().mockResolvedValue(true),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PayrollService,
        PayrollCalculatorService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: NotificationsService, useValue: mockNotificationsService },
      ],
    }).compile();

    payrollService = module.get<PayrollService>(PayrollService);
    payrollCalculator = module.get<PayrollCalculatorService>(
      PayrollCalculatorService,
    );

    jest.clearAllMocks();
  });

  // ============================================================
  // TEST GROUP 1: SALARY PROFILE & HISTORY
  // ============================================================
  describe("Salary Profile & History", () => {
    it("1. should create or update salary profile with history and audit log", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: mockEmployeeId,
        baseSalary: new Prisma.Decimal(12000),
      });
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue(null);
      mockPrismaService.salaryProfile.create.mockResolvedValue({
        id: "sal-prof-1",
        employeeId: mockEmployeeId,
        basicSalary: new Prisma.Decimal(15000),
        allowances: new Prisma.Decimal(2000),
      });

      const result = await payrollService.setSalaryProfile(
        {
          employeeId: mockEmployeeId,
          basicSalary: 15000,
          allowances: 2000,
          reason: "Initial setup",
        },
        mockApproverId,
      );

      expect(result.basicSalary).toEqual(new Prisma.Decimal(15000));
      expect(mockPrismaService.salaryHistory.create).toHaveBeenCalled();
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });

    it("2. should append versioned record to salary history on update", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: mockEmployeeId,
      });
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        id: "sal-prof-1",
        employeeId: mockEmployeeId,
        basicSalary: new Prisma.Decimal(15000),
        allowances: new Prisma.Decimal(2000),
      });
      mockPrismaService.salaryProfile.update.mockResolvedValue({
        id: "sal-prof-1",
        basicSalary: new Prisma.Decimal(18000),
        allowances: new Prisma.Decimal(2500),
      });

      await payrollService.setSalaryProfile(
        {
          employeeId: mockEmployeeId,
          basicSalary: 18000,
          allowances: 2500,
          reason: "Promotion bump",
        },
        mockApproverId,
      );

      expect(mockPrismaService.salaryHistory.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            oldBasicSalary: new Prisma.Decimal(15000),
            newBasicSalary: new Prisma.Decimal(18000),
            reason: "Promotion bump",
          }),
        }),
      );
    });

    it("3. should allow employee to view own salary profile and prevent unauthorized IDOR", async () => {
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        employeeId: mockEmployeeId,
        basicSalary: new Prisma.Decimal(15000),
      });

      // Owner can view
      const ownResult = await payrollService.getSalaryProfile(mockEmployeeId, {
        id: mockUserId,
        role: Role.EMPLOYEE,
        employeeProfileId: mockEmployeeId,
      });
      expect(ownResult.basicSalary).toEqual(new Prisma.Decimal(15000));

      // Another employee forbidden
      await expect(
        payrollService.getSalaryProfile(mockEmployeeId, {
          id: "other-user",
          role: Role.EMPLOYEE,
          employeeProfileId: "other-emp",
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  // ============================================================
  // TEST GROUP 2: SALARY ADVANCES WORKFLOW
  // ============================================================
  describe("Salary Advances & Installments", () => {
    it("4. should create salary advance request deriving employee from authenticated session", async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: mockUserId,
        status: UserStatus.ACTIVE,
        employeeProfile: {
          id: mockEmployeeId,
          baseSalary: new Prisma.Decimal(15000),
        },
      });
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        basicSalary: new Prisma.Decimal(15000),
      });
      mockPrismaService.financialAdvance.findFirst.mockResolvedValue(null);
      mockPrismaService.financialAdvance.create.mockResolvedValue({
        id: "adv-1",
        employeeId: mockEmployeeId,
        amount: new Prisma.Decimal(5000),
        status: AdvanceStatus.PENDING,
      });

      const result = await payrollService.requestAdvance(mockUserId, {
        amount: 5000,
        requestedInstallments: 3,
        reason: "Medical emergency",
      });

      expect(result.amount).toEqual(new Prisma.Decimal(5000));
      expect(result.status).toBe(AdvanceStatus.PENDING);
    });

    it("5. should reject advance request if amount <= 0", async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: mockUserId,
        status: UserStatus.ACTIVE,
        employeeProfile: { id: mockEmployeeId },
      });

      await expect(
        payrollService.requestAdvance(mockUserId, {
          amount: 0,
          reason: "Invalid amount",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("6. should reject advance request if exceeding 3x monthly salary limit", async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: mockUserId,
        status: UserStatus.ACTIVE,
        employeeProfile: {
          id: mockEmployeeId,
          baseSalary: new Prisma.Decimal(10000),
        },
      });
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        basicSalary: new Prisma.Decimal(10000),
      });

      await expect(
        payrollService.requestAdvance(mockUserId, {
          amount: 50000, // exceeds 30,000 max
          reason: "Excessive request",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("7. should reject advance if active pending advance already exists", async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: mockUserId,
        status: UserStatus.ACTIVE,
        employeeProfile: { id: mockEmployeeId },
      });
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        basicSalary: new Prisma.Decimal(15000),
      });
      mockPrismaService.financialAdvance.findFirst.mockResolvedValue({
        id: "existing-pending-adv",
        status: AdvanceStatus.PENDING,
      });

      await expect(
        payrollService.requestAdvance(mockUserId, {
          amount: 3000,
          reason: "Second request",
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("8. should return existing advance if idempotencyKey matches (idempotency safety)", async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: mockUserId,
        status: UserStatus.ACTIVE,
        employeeProfile: { id: mockEmployeeId },
      });
      mockPrismaService.financialAdvance.findUnique.mockResolvedValue({
        id: "adv-idemp-1",
        employeeId: mockEmployeeId,
        idempotencyKey: "idemp-key-123",
        amount: new Prisma.Decimal(5000),
      });

      const res = await payrollService.requestAdvance(mockUserId, {
        amount: 5000,
        reason: "Duplicate call",
        idempotencyKey: "idemp-key-123",
      });

      expect(res.id).toBe("adv-idemp-1");
      expect(mockPrismaService.financialAdvance.create).not.toHaveBeenCalled();
    });

    it("9. should approve advance, set ACTIVE status, and generate installment schedule", async () => {
      mockPrismaService.financialAdvance.findUnique.mockResolvedValue({
        id: "adv-1",
        employeeId: mockEmployeeId,
        amount: new Prisma.Decimal(6000),
        requestedInstallments: 3,
        status: AdvanceStatus.PENDING,
        employee: { user: { id: mockUserId } },
      });
      mockPrismaService.financialAdvance.update.mockResolvedValue({
        id: "adv-1",
        status: AdvanceStatus.ACTIVE,
        approvedAmount: new Prisma.Decimal(6000),
        remainingAmount: new Prisma.Decimal(6000),
      });

      const result = await payrollService.approveAdvance(
        "adv-1",
        mockApproverId,
        {
          approvedAmount: 6000,
          installmentsCount: 3,
          remarks: "Approved by HR",
        },
      );

      expect(result.status).toBe(AdvanceStatus.ACTIVE);
      expect(mockPrismaService.advanceInstallment.create).toHaveBeenCalledTimes(
        3,
      );
      expect(mockNotificationsService.sendNotification).toHaveBeenCalled();
    });

    it("10. should reject advance with mandatory reason", async () => {
      mockPrismaService.financialAdvance.findUnique.mockResolvedValue({
        id: "adv-1",
        status: AdvanceStatus.PENDING,
        employee: { user: { id: mockUserId } },
      });
      mockPrismaService.financialAdvance.update.mockResolvedValue({
        id: "adv-1",
        status: AdvanceStatus.REJECTED,
      });

      const res = await payrollService.rejectAdvance("adv-1", mockApproverId, {
        reason: "Probation period active",
      });

      expect(res.status).toBe(AdvanceStatus.REJECTED);
      expect(mockNotificationsService.sendNotification).toHaveBeenCalledWith(
        mockUserId,
        expect.any(String),
        expect.stringContaining("Probation period active"),
        expect.any(String),
        expect.any(Object),
      );
    });

    it("11. should fail rejecting advance if reason is empty", async () => {
      await expect(
        payrollService.rejectAdvance("adv-1", mockApproverId, { reason: "" }),
      ).rejects.toThrow(BadRequestException);
    });

    it("12. should prevent double approval of already approved advance", async () => {
      mockPrismaService.financialAdvance.findUnique.mockResolvedValue({
        id: "adv-1",
        status: AdvanceStatus.ACTIVE,
      });

      await expect(
        payrollService.approveAdvance("adv-1", mockApproverId, {}),
      ).rejects.toThrow(BadRequestException);
    });

    it("13. should record partial installment payment and update remaining amount", async () => {
      mockPrismaService.advanceInstallment.findUnique.mockResolvedValue({
        id: "inst-1",
        advanceId: "adv-1",
        amount: new Prisma.Decimal(2000),
        paidAmount: new Prisma.Decimal(0),
        remainingAmount: new Prisma.Decimal(2000),
        status: InstallmentStatus.PENDING,
        advance: {
          id: "adv-1",
          paidAmount: new Prisma.Decimal(0),
          remainingAmount: new Prisma.Decimal(6000),
          employee: { user: { id: mockUserId } },
        },
      });
      mockPrismaService.advanceInstallment.update.mockResolvedValue({
        id: "inst-1",
        paidAmount: new Prisma.Decimal(1000),
        remainingAmount: new Prisma.Decimal(1000),
        status: InstallmentStatus.PARTIALLY_PAID,
      });

      const res = await payrollService.recordInstallmentPayment(
        "inst-1",
        mockApproverId,
        {
          amount: 1000,
          notes: "Partial bank transfer",
        },
      );

      expect(res.status).toBe(InstallmentStatus.PARTIALLY_PAID);
      expect(mockPrismaService.financialAdvance.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            paidAmount: new Prisma.Decimal(1000),
            remainingAmount: new Prisma.Decimal(5000),
            status: AdvanceStatus.PARTIALLY_PAID,
          }),
        }),
      );
    });

    it("14. should block overpayment exceeding remaining installment amount", async () => {
      mockPrismaService.advanceInstallment.findUnique.mockResolvedValue({
        id: "inst-1",
        amount: new Prisma.Decimal(2000),
        remainingAmount: new Prisma.Decimal(1000),
        status: InstallmentStatus.PARTIALLY_PAID,
      });

      await expect(
        payrollService.recordInstallmentPayment("inst-1", mockApproverId, {
          amount: 1500, // greater than 1000 remaining
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it("15. should block payment on already fully paid installment", async () => {
      mockPrismaService.advanceInstallment.findUnique.mockResolvedValue({
        id: "inst-1",
        status: InstallmentStatus.PAID,
      });

      await expect(
        payrollService.recordInstallmentPayment("inst-1", mockApproverId, {
          amount: 500,
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ============================================================
  // TEST GROUP 3: MANUAL FINANCIAL DEDUCTIONS
  // ============================================================
  describe("Manual Financial Deductions", () => {
    it("16. should create financial deduction and notify employee", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: mockEmployeeId,
        user: { id: mockUserId },
      });
      mockPrismaService.financialDeduction.create.mockResolvedValue({
        id: "ded-1",
        amount: new Prisma.Decimal(500),
        type: DeductionType.PENALTY,
      });

      const res = await payrollService.createDeduction(
        {
          employeeId: mockEmployeeId,
          type: DeductionType.PENALTY,
          amount: 500,
          reason: "Company asset damage",
          effectiveDate: "2026-08-15",
        },
        mockApproverId,
      );

      expect(res.amount).toEqual(new Prisma.Decimal(500));
      expect(mockNotificationsService.sendNotification).toHaveBeenCalled();
    });

    it("17. should reject deduction if amount <= 0", async () => {
      mockPrismaService.employeeProfile.findUnique.mockResolvedValue({
        id: mockEmployeeId,
      });

      await expect(
        payrollService.createDeduction(
          {
            employeeId: mockEmployeeId,
            type: DeductionType.OTHER,
            amount: -100,
            reason: "Invalid",
            effectiveDate: "2026-08-15",
          },
          mockApproverId,
        ),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ============================================================
  // TEST GROUP 4: PAYROLL CALCULATION ENGINE & ANOMALIES
  // ============================================================
  describe("Payroll Calculation Engine (PayrollCalculatorService)", () => {
    const periodStart = new Date("2026-08-01");
    const periodEnd = new Date("2026-08-31");

    it("18. should calculate base salary & allowance line items accurately", async () => {
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        employeeId: mockEmployeeId,
        basicSalary: new Prisma.Decimal(12000),
        allowances: new Prisma.Decimal(3000),
        currency: "EGP",
      });
      mockPrismaService.attendanceRecord.findMany.mockResolvedValue([]);
      mockPrismaService.request.findMany.mockResolvedValue([]);
      mockPrismaService.advanceInstallment.findMany.mockResolvedValue([]);
      mockPrismaService.financialDeduction.findMany.mockResolvedValue([]);

      const result = await payrollCalculator.calculateEmployeePayroll(
        mockEmployeeId,
        periodStart,
        periodEnd,
        mockPrismaService,
      );

      expect(result.grossSalary).toEqual(new Prisma.Decimal(15000));
      expect(result.totalDeductions).toEqual(new Prisma.Decimal(0));
      expect(result.netSalary).toEqual(new Prisma.Decimal(15000));
      expect(result.lineItems).toHaveLength(2);
    });

    it("19. should convert unexcused late minutes into financial deduction line item", async () => {
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        basicSalary: new Prisma.Decimal(14400), // daily = 480, hourly = 60, minute = 1.0 EGP
        allowances: new Prisma.Decimal(0),
      });
      mockPrismaService.attendanceRecord.findMany.mockResolvedValue([
        { lateMinutes: 60, status: AttendanceStatus.LATE, notes: null },
      ]);
      mockPrismaService.request.findMany.mockResolvedValue([]);
      mockPrismaService.advanceInstallment.findMany.mockResolvedValue([]);
      mockPrismaService.financialDeduction.findMany.mockResolvedValue([]);

      const result = await payrollCalculator.calculateEmployeePayroll(
        mockEmployeeId,
        periodStart,
        periodEnd,
        mockPrismaService,
      );

      const lateItem = result.lineItems.find(
        (i) => i.type === PayrollLineItemType.LATE_DEDUCTION,
      );
      expect(lateItem).toBeDefined();
      expect(lateItem?.amount).toEqual(new Prisma.Decimal(60));
      expect(result.netSalary).toEqual(new Prisma.Decimal(14340));
    });

    it("20. should convert unexcused absence days into financial deduction", async () => {
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        basicSalary: new Prisma.Decimal(15000), // daily = 500 EGP
        allowances: new Prisma.Decimal(0),
      });
      mockPrismaService.attendanceRecord.findMany.mockResolvedValue([
        { status: AttendanceStatus.ABSENT, notes: null },
        { status: AttendanceStatus.ABSENT, notes: null },
      ]);
      mockPrismaService.request.findMany.mockResolvedValue([]);
      mockPrismaService.advanceInstallment.findMany.mockResolvedValue([]);
      mockPrismaService.financialDeduction.findMany.mockResolvedValue([]);

      const result = await payrollCalculator.calculateEmployeePayroll(
        mockEmployeeId,
        periodStart,
        periodEnd,
        mockPrismaService,
      );

      const absItem = result.lineItems.find(
        (i) => i.type === PayrollLineItemType.ABSENCE_DEDUCTION,
      );
      expect(absItem).toBeDefined();
      expect(absItem?.amount).toEqual(new Prisma.Decimal(1000));
      expect(result.netSalary).toEqual(new Prisma.Decimal(14000));
    });

    it("21. should convert approved unpaid leave requests into financial deductions", async () => {
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        basicSalary: new Prisma.Decimal(15000), // daily = 500 EGP
        allowances: new Prisma.Decimal(0),
      });
      mockPrismaService.attendanceRecord.findMany.mockResolvedValue([]);
      mockPrismaService.request.findMany.mockResolvedValue([
        {
          id: "unpaid-req-1",
          type: RequestType.UNPAID_LEAVE,
          startDate: new Date("2026-08-10"),
          endDate: new Date("2026-08-12"), // 3 days
          reason: "Personal unpaid leave",
        },
      ]);
      mockPrismaService.advanceInstallment.findMany.mockResolvedValue([]);
      mockPrismaService.financialDeduction.findMany.mockResolvedValue([]);

      const result = await payrollCalculator.calculateEmployeePayroll(
        mockEmployeeId,
        periodStart,
        periodEnd,
        mockPrismaService,
      );

      const unpaidItem = result.lineItems.find(
        (i) => i.type === PayrollLineItemType.UNPAID_LEAVE_DEDUCTION,
      );
      expect(unpaidItem).toBeDefined();
      expect(unpaidItem?.amount).toEqual(new Prisma.Decimal(1500)); // 3 days * 500
      expect(result.netSalary).toEqual(new Prisma.Decimal(13500));
    });

    it("22. should include active advance installment due in period as deduction", async () => {
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        basicSalary: new Prisma.Decimal(15000),
        allowances: new Prisma.Decimal(0),
      });
      mockPrismaService.attendanceRecord.findMany.mockResolvedValue([]);
      mockPrismaService.request.findMany.mockResolvedValue([]);
      mockPrismaService.advanceInstallment.findMany.mockResolvedValue([
        {
          id: "inst-due-1",
          installmentNumber: 1,
          remainingAmount: new Prisma.Decimal(2000),
          advance: { reason: "Medical loan" },
        },
      ]);
      mockPrismaService.financialDeduction.findMany.mockResolvedValue([]);

      const result = await payrollCalculator.calculateEmployeePayroll(
        mockEmployeeId,
        periodStart,
        periodEnd,
        mockPrismaService,
      );

      const advItem = result.lineItems.find(
        (i) => i.type === PayrollLineItemType.ADVANCE_INSTALLMENT,
      );
      expect(advItem).toBeDefined();
      expect(advItem?.amount).toEqual(new Prisma.Decimal(2000));
      expect(result.netSalary).toEqual(new Prisma.Decimal(13000));
      expect(result.advanceInstallmentIds).toContain("inst-due-1");
    });

    it("23. should floor netSalary at 0 if deductions exceed gross earnings", async () => {
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        basicSalary: new Prisma.Decimal(3000),
        allowances: new Prisma.Decimal(0),
      });
      mockPrismaService.attendanceRecord.findMany.mockResolvedValue([]);
      mockPrismaService.request.findMany.mockResolvedValue([]);
      mockPrismaService.advanceInstallment.findMany.mockResolvedValue([]);
      mockPrismaService.financialDeduction.findMany.mockResolvedValue([
        {
          id: "huge-ded",
          type: DeductionType.DAMAGE,
          amount: new Prisma.Decimal(5000),
          reason: "Heavy damage",
        },
      ]);

      const result = await payrollCalculator.calculateEmployeePayroll(
        mockEmployeeId,
        periodStart,
        periodEnd,
        mockPrismaService,
      );

      expect(result.grossSalary).toEqual(new Prisma.Decimal(3000));
      expect(result.totalDeductions).toEqual(new Prisma.Decimal(5000));
      expect(result.netSalary).toEqual(new Prisma.Decimal(0));
    });
  });

  // ============================================================
  // TEST GROUP 5: PAYROLL PERIODS & FINALIZATION
  // ============================================================
  describe("Payroll Periods & Finalization", () => {
    it("24. should create new payroll period with unique name", async () => {
      mockPrismaService.payrollPeriod.findUnique.mockResolvedValue(null);
      mockPrismaService.payrollPeriod.create.mockResolvedValue({
        id: "period-2026-08",
        name: "2026-08",
        status: PayrollPeriodStatus.OPEN,
      });

      const res = await payrollService.createPayrollPeriod(
        {
          name: "2026-08",
          startDate: "2026-08-01",
          endDate: "2026-08-31",
        },
        mockApproverId,
      );

      expect(res.name).toBe("2026-08");
      expect(res.status).toBe(PayrollPeriodStatus.OPEN);
    });

    it("25. should block duplicate payroll period creation", async () => {
      mockPrismaService.payrollPeriod.findUnique.mockResolvedValue({
        id: "existing-p",
      });

      await expect(
        payrollService.createPayrollPeriod(
          {
            name: "2026-08",
            startDate: "2026-08-01",
            endDate: "2026-08-31",
          },
          mockApproverId,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it("26. should calculate workforce payroll for period and transition to REVIEW", async () => {
      mockPrismaService.payrollPeriod.findUnique.mockResolvedValue({
        id: "p-1",
        name: "2026-08",
        startDate: new Date("2026-08-01"),
        endDate: new Date("2026-08-31"),
        status: PayrollPeriodStatus.OPEN,
      });
      mockPrismaService.employeeProfile.findMany.mockResolvedValue([
        { id: mockEmployeeId },
      ]);
      mockPrismaService.salaryProfile.findUnique.mockResolvedValue({
        basicSalary: new Prisma.Decimal(15000),
        allowances: new Prisma.Decimal(0),
      });
      mockPrismaService.attendanceRecord.findMany.mockResolvedValue([]);
      mockPrismaService.request.findMany.mockResolvedValue([]);
      mockPrismaService.advanceInstallment.findMany.mockResolvedValue([]);
      mockPrismaService.financialDeduction.findMany.mockResolvedValue([]);
      mockPrismaService.payrollRecord.findUnique.mockResolvedValue(null);
      mockPrismaService.payrollRecord.create.mockResolvedValue({ id: "rec-1" });

      const res = await payrollService.calculatePeriodPayroll(
        "p-1",
        {},
        mockApproverId,
      );

      expect(res.recordsCount).toBe(1);
      expect(mockPrismaService.payrollPeriod.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { status: PayrollPeriodStatus.REVIEW },
        }),
      );
    });

    it("27. should finalize payroll period, lock records, and mark advance installments as PAID", async () => {
      mockPrismaService.payrollPeriod.findUnique.mockResolvedValue({
        id: "p-1",
        name: "2026-08",
        status: PayrollPeriodStatus.REVIEW,
        payrollRecords: [
          {
            id: "rec-1",
            lineItems: [
              {
                type: PayrollLineItemType.ADVANCE_INSTALLMENT,
                amount: new Prisma.Decimal(2000),
                sourceId: "inst-1",
              },
            ],
          },
        ],
      });
      mockPrismaService.advanceInstallment.findUnique.mockResolvedValue({
        id: "inst-1",
        amount: new Prisma.Decimal(2000),
        status: InstallmentStatus.PENDING,
        advance: {
          id: "adv-1",
          paidAmount: new Prisma.Decimal(0),
          remainingAmount: new Prisma.Decimal(2000),
        },
      });

      const res = await payrollService.finalizePayrollPeriod(
        "p-1",
        mockApproverId,
      );

      expect(res.message).toContain("finalized successfully");
      expect(mockPrismaService.advanceInstallment.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: "inst-1" },
          data: expect.objectContaining({
            status: InstallmentStatus.PAID,
            remainingAmount: new Prisma.Decimal(0),
          }),
        }),
      );
      expect(mockPrismaService.financialAdvance.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: "adv-1" },
          data: expect.objectContaining({
            status: AdvanceStatus.PAID,
            remainingAmount: new Prisma.Decimal(0),
          }),
        }),
      );
    });

    it("28. should block re-calculating or modifying finalized payroll period", async () => {
      mockPrismaService.payrollPeriod.findUnique.mockResolvedValue({
        id: "p-1",
        status: PayrollPeriodStatus.FINALIZED,
      });

      await expect(
        payrollService.calculatePeriodPayroll("p-1", {}, mockApproverId),
      ).rejects.toThrow(BadRequestException);
    });

    it("29. should apply post-finalization adjustment and update record net salary", async () => {
      mockPrismaService.payrollRecord.findUnique.mockResolvedValue({
        id: "rec-1",
        grossSalary: new Prisma.Decimal(15000),
        totalDeductions: new Prisma.Decimal(1000),
        netSalary: new Prisma.Decimal(14000),
      });
      mockPrismaService.payrollAdjustment.create.mockResolvedValue({
        id: "adj-1",
      });
      mockPrismaService.payrollRecord.update.mockResolvedValue({
        id: "rec-1",
        grossSalary: new Prisma.Decimal(16000),
        totalDeductions: new Prisma.Decimal(1000),
        netSalary: new Prisma.Decimal(15000),
      });

      const res = await payrollService.createPayrollAdjustment(
        "rec-1",
        mockApproverId,
        {
          type: PayrollLineItemType.BONUS,
          amount: 1000,
          isDeduction: false,
          reason: "Performance bonus retro",
        },
      );

      expect(res.netSalary).toEqual(new Prisma.Decimal(15000));
      expect(mockPrismaService.payrollLineItem.create).toHaveBeenCalled();
      expect(mockPrismaService.auditLog.create).toHaveBeenCalled();
    });

    it("30. should protect payroll details from IDOR across different employees", async () => {
      mockPrismaService.payrollRecord.findUnique.mockResolvedValue({
        id: "rec-1",
        employeeId: mockEmployeeId,
      });

      // Employee can view own
      const own = await payrollService.getPayrollRecordDetails("rec-1", {
        id: mockUserId,
        role: Role.EMPLOYEE,
        employeeProfileId: mockEmployeeId,
      });
      expect(own.id).toBe("rec-1");

      // Other employee blocked
      await expect(
        payrollService.getPayrollRecordDetails("rec-1", {
          id: "other-user",
          role: Role.EMPLOYEE,
          employeeProfileId: "other-emp-id",
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
