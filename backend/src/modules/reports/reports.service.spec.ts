import { Test, TestingModule } from "@nestjs/testing";
import { ReportsService } from "./reports.service";
import { PrismaService } from "../../prisma/prisma.service";
import {
  AttendanceStatus,
  AuditAction,
  DeductionType,
  PayrollPeriodStatus,
  RequestStatus,
  RequestType,
  UserStatus,
} from "@prisma/client";
import { BadRequestException, NotFoundException } from "@nestjs/common";
import { CsvExporterUtil } from "./utils/csv-exporter.util";
import { DateRangeUtil } from "./utils/date-range.util";

describe("Phase 07 — Reports, Analytics & HR Intelligence (33 Test Scenarios)", () => {
  let reportsService: ReportsService;
  let mockPrisma: any;

  beforeEach(async () => {
    mockPrisma = {
      employeeProfile: {
        count: jest.fn().mockResolvedValue(10),
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue({
          id: "emp-1",
          userId: "user-1",
          employeeCode: "CW-100",
          firstName: "Omar",
          lastName: "Hassan",
          department: "Engineering",
          jobTitle: "Senior Engineer",
        }),
        groupBy: jest.fn().mockResolvedValue([
          { department: "Engineering", _count: { id: 6 } },
          { department: "Design", _count: { id: 4 } },
        ]),
      },
      user: {
        count: jest.fn().mockImplementation(({ where }) => {
          if (where?.status === UserStatus.ACTIVE) return Promise.resolve(9);
          if (where?.status?.in) return Promise.resolve(1);
          return Promise.resolve(10);
        }),
      },
      attendanceRecord: {
        count: jest.fn().mockResolvedValue(20),
        findMany: jest.fn().mockResolvedValue([
          {
            id: "att-1",
            employeeId: "emp-1",
            date: new Date("2026-08-01"),
            status: AttendanceStatus.PRESENT,
            checkInTime: new Date("2026-08-01T09:00:00Z"),
            checkOutTime: new Date("2026-08-01T17:00:00Z"),
            lateMinutes: 0,
            earlyLeaveMinutes: 0,
            workDurationMinutes: 480,
            isSuspicious: false,
            isManualEntry: false,
            employee: {
              id: "emp-1",
              employeeCode: "CW-100",
              firstName: "Omar",
              lastName: "Hassan",
              department: "Engineering",
              jobTitle: "Senior Engineer",
            },
            workplace: { id: "wp-1", name: "Main HQ", code: "HQ-01" },
          },
          {
            id: "att-2",
            employeeId: "emp-2",
            date: new Date("2026-08-01"),
            status: AttendanceStatus.LATE,
            checkInTime: new Date("2026-08-01T09:30:00Z"),
            checkOutTime: new Date("2026-08-01T17:00:00Z"),
            lateMinutes: 30,
            earlyLeaveMinutes: 0,
            workDurationMinutes: 450,
            isSuspicious: false,
            isManualEntry: false,
            employee: {
              id: "emp-2",
              employeeCode: "CW-101",
              firstName: "Layla",
              lastName: "Nour",
              department: "Design",
              jobTitle: "UI Designer",
            },
            workplace: { id: "wp-1", name: "Main HQ", code: "HQ-01" },
          },
        ]),
        aggregate: jest.fn().mockResolvedValue({
          _sum: {
            lateMinutes: 30,
            earlyLeaveMinutes: 0,
            workDurationMinutes: 930,
          },
          _avg: {
            lateMinutes: 15,
            earlyLeaveMinutes: 0,
            workDurationMinutes: 465,
          },
          _count: { id: 2 },
        }),
        groupBy: jest.fn().mockResolvedValue([
          { status: AttendanceStatus.PRESENT, _count: { id: 1 } },
          { status: AttendanceStatus.LATE, _count: { id: 1 } },
        ]),
      },
      attendanceEvent: {
        count: jest.fn().mockResolvedValue(2),
      },
      request: {
        count: jest.fn().mockResolvedValue(5),
        findMany: jest.fn().mockResolvedValue([
          {
            id: "req-1",
            type: RequestType.ANNUAL_LEAVE,
            status: RequestStatus.APPROVED,
            createdAt: new Date("2026-08-01T08:00:00Z"),
            reviewedAt: new Date("2026-08-01T10:00:00Z"),
            reason: "Vacation",
          },
        ]),
        groupBy: jest.fn().mockImplementation(({ by }) => {
          if (by[0] === "type") {
            return Promise.resolve([
              { type: RequestType.ANNUAL_LEAVE, _count: { id: 3 } },
              { type: RequestType.PERMISSION, _count: { id: 2 } },
            ]);
          }
          return Promise.resolve([
            { status: RequestStatus.APPROVED, _count: { id: 4 } },
            { status: RequestStatus.REJECTED, _count: { id: 1 } },
          ]);
        }),
      },
      financialAdvance: {
        count: jest.fn().mockResolvedValue(3),
        findMany: jest.fn().mockResolvedValue([]),
        aggregate: jest.fn().mockResolvedValue({
          _sum: {
            amount: 15000,
            approvedAmount: 12000,
            paidAmount: 5000,
            remainingAmount: 7000,
          },
          _avg: { amount: 5000 },
          _count: { id: 3 },
        }),
        groupBy: jest.fn().mockResolvedValue([
          { status: "APPROVED", _count: { id: 2 }, _sum: { amount: 10000 } },
          { status: "PENDING", _count: { id: 1 }, _sum: { amount: 5000 } },
        ]),
      },
      financialDeduction: {
        aggregate: jest.fn().mockResolvedValue({
          _sum: { amount: 2500 },
          _avg: { amount: 500 },
          _count: { id: 5 },
        }),
        groupBy: jest.fn().mockResolvedValue([
          {
            type: DeductionType.LATENESS,
            _count: { id: 3 },
            _sum: { amount: 1500 },
          },
          {
            type: DeductionType.ABSENCE,
            _count: { id: 2 },
            _sum: { amount: 1000 },
          },
        ]),
        findMany: jest.fn().mockResolvedValue([
          { amount: 1500, employee: { department: "Engineering" } },
          { amount: 1000, employee: { department: "Design" } },
        ]),
      },
      payrollRecord: {
        aggregate: jest.fn().mockResolvedValue({
          _sum: {
            basicSalary: 80000,
            allowances: 10000,
            grossSalary: 90000,
            totalDeductions: 5000,
            netSalary: 85000,
          },
          _avg: {
            grossSalary: 9000,
            netSalary: 8500,
          },
          _count: { id: 10 },
        }),
        findMany: jest.fn().mockResolvedValue([
          {
            basicSalary: 40000,
            allowances: 5000,
            grossSalary: 45000,
            totalDeductions: 2500,
            netSalary: 42500,
            employee: { department: "Engineering", workplaceId: "wp-1" },
            payrollPeriod: {
              id: "p-1",
              name: "2026-08",
              startDate: new Date("2026-08-01"),
              endDate: new Date("2026-08-31"),
            },
          },
        ]),
        findFirst: jest.fn().mockResolvedValue({
          basicSalary: 20000,
          allowances: 2000,
          grossSalary: 22000,
          totalDeductions: 1000,
          netSalary: 21000,
          payrollPeriod: { name: "2026-08" },
        }),
      },
      payrollPeriod: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: "p-1",
            name: "2026-08",
            status: PayrollPeriodStatus.OPEN,
            _count: { payrollRecords: 10 },
          },
        ]),
      },
      workplace: {
        count: jest.fn().mockResolvedValue(2),
        findMany: jest.fn().mockResolvedValue([
          {
            id: "wp-1",
            name: "Main HQ",
            code: "HQ-01",
            isActive: true,
            radiusMeters: 100,
            _count: { employees: 8, attendances: 15 },
          },
        ]),
      },
      auditLog: {
        create: jest.fn().mockResolvedValue({ id: "audit-1" }),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReportsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    reportsService = module.get<ReportsService>(ReportsService);
  });

  // ============================================================
  // 1. Dashboard KPI
  // ============================================================
  it("Scenario 01: Should compute HR Dashboard KPIs accurately", async () => {
    const res = await reportsService.getDashboardSummary();

    expect(res).toBeDefined();
    expect(res.employees.total).toBe(10);
    expect(res.employees.active).toBe(9);
    expect(res.employees.inactive).toBe(1);
    expect(res.todayAttendance).toBeDefined();
    expect(res.pendingActions.requests).toBe(5);
    expect(res.pendingActions.advances).toBe(3);
    expect(res.workplaces.active).toBe(2);
    expect(res.monthlyFinancials.netPayroll).toBe(85000);
  });

  // ============================================================
  // 2. Attendance Report
  // ============================================================
  it("Scenario 02: Should generate comprehensive attendance report with pagination", async () => {
    const res = await reportsService.getAttendanceReport({
      startDate: "2026-08-01",
      endDate: "2026-08-31",
      page: 1,
      limit: 10,
    });

    expect(res.summary).toBeDefined();
    expect(res.summary.expectedWorkingDays).toBeGreaterThan(0);
    expect(res.data.length).toBe(2);
    expect(res.meta.total).toBe(20);
    expect(res.meta.totalPages).toBe(2);
  });

  // ============================================================
  // 3. Attendance Rate Calculation
  // ============================================================
  it("Scenario 03: Should calculate attendance rate correctly based on expected working days", async () => {
    const res = await reportsService.getAttendanceReport({
      startDate: "2026-08-01",
      endDate: "2026-08-07",
    });

    expect(res.summary.attendanceRate).toBeGreaterThanOrEqual(0);
    expect(res.summary.attendanceRate).toBeLessThanOrEqual(100);
  });

  // ============================================================
  // 4. Late Analytics
  // ============================================================
  it("Scenario 04: Should aggregate late analytics, top offenders, and department distributions", async () => {
    const res = await reportsService.getLateAnalytics({
      startDate: "2026-08-01",
      endDate: "2026-08-31",
    });

    expect(res.summary.totalLateMinutes).toBe(30);
    expect(res.summary.averageLateMinutes).toBe(15);
    expect(res.topLateEmployees.length).toBeGreaterThan(0);
    expect(res.departmentDistribution).toBeDefined();
  });

  // ============================================================
  // 5. Absence Analytics
  // ============================================================
  it("Scenario 05: Should calculate absence counts, approved vs unapproved, and absence rates", async () => {
    const res = await reportsService.getAbsenceAnalytics({
      startDate: "2026-08-01",
      endDate: "2026-08-31",
    });

    expect(res.summary.totalAbsenceCount).toBeDefined();
    expect(res.summary.absenceRate).toBeDefined();
    expect(res.departmentAbsence).toBeDefined();
  });

  // ============================================================
  // 6. Request Analytics
  // ============================================================
  it("Scenario 06: Should calculate request approval and rejection rates", async () => {
    const res = await reportsService.getRequestAnalytics({
      startDate: "2026-08-01",
      endDate: "2026-08-31",
    });

    expect(res.summary.totalRequests).toBe(5);
    expect(res.summary.approvalRate).toBe(80); // 4 out of 5 resolved = 80%
    expect(res.summary.rejectionRate).toBe(20); // 1 out of 5 resolved = 20%
    expect(res.byType.length).toBe(2);
  });

  // ============================================================
  // 7. Request Processing Duration
  // ============================================================
  it("Scenario 07: Should calculate average request processing duration in hours", async () => {
    const res = await reportsService.getRequestAnalytics({
      startDate: "2026-08-01",
      endDate: "2026-08-31",
    });

    expect(res.summary.averageProcessingDurationHours).toBe(2); // 8:00 to 10:00 = 2 hours
  });

  // ============================================================
  // 8. Payroll Analytics
  // ============================================================
  it("Scenario 08: Should aggregate gross, net, deductions, and departmental payroll", async () => {
    const res = await reportsService.getPayrollAnalytics({}, { id: "admin-1" });

    expect(res.summary.grossPayroll).toBe(90000);
    expect(res.summary.netPayroll).toBe(85000);
    expect(res.summary.totalDeductions).toBe(5000);
    expect(res.departmentPayroll.length).toBeGreaterThan(0);
    expect(mockPrisma.auditLog.create).toHaveBeenCalled();
  });

  // ============================================================
  // 9. Deduction Analytics
  // ============================================================
  it("Scenario 09: Should aggregate deductions by type and department", async () => {
    const res = await reportsService.getDeductionAnalytics({
      startDate: "2026-08-01",
      endDate: "2026-08-31",
    });

    expect(res.summary.totalDeductionAmount).toBe(2500);
    expect(res.byType.length).toBe(2);
    expect(res.byDepartment.length).toBe(2);
  });

  // ============================================================
  // 10. Advance Analytics
  // ============================================================
  it("Scenario 10: Should aggregate financial advances, active balances, and repayments", async () => {
    const res = await reportsService.getAdvanceAnalytics({
      startDate: "2026-08-01",
      endDate: "2026-08-31",
    });

    expect(res.summary.totalRequestedAmount).toBe(15000);
    expect(res.summary.totalApprovedAmount).toBe(12000);
    expect(res.summary.totalOutstandingBalance).toBe(7000);
    expect(res.byStatus.length).toBe(2);
  });

  // ============================================================
  // 11. Employee Distribution Analytics
  // ============================================================
  it("Scenario 11: Should return employee distribution by department, workplace, and job title", async () => {
    const res = await reportsService.getEmployeeAnalytics({});

    expect(res.overview.total).toBe(10);
    expect(res.overview.active).toBe(9);
    expect(res.byDepartment.length).toBe(2);
    expect(res.byWorkplace.length).toBe(2);
  });

  // ============================================================
  // 12. Department Performance Analytics
  // ============================================================
  it("Scenario 12: Should aggregate department performance statistics", async () => {
    const res = await reportsService.getDepartmentStats();

    expect(res.length).toBe(2);
    expect(res[0].department).toBe("Engineering");
    expect(res[0].employeeCount).toBe(6);
  });

  // ============================================================
  // 13. Workplace Operational Analytics
  // ============================================================
  it("Scenario 13: Should calculate workplace operational stats and geofence breaches", async () => {
    const res = await reportsService.getWorkplaceAnalytics({});

    expect(res.length).toBe(1);
    expect(res[0].name).toBe("Main HQ");
    expect(res[0].employeeCount).toBe(8);
  });

  // ============================================================
  // 14. Security Telemetry Analytics
  // ============================================================
  it("Scenario 14: Should compute security telemetry (geofence breaches, suspicious signals, accuracy)", async () => {
    const res = await reportsService.getSecurityAnalytics(
      { startDate: "2026-08-01", endDate: "2026-08-31" },
      { id: "admin-1" },
    );

    expect(res.summary.rejectedAttempts).toBe(2);
    expect(res.summary.securityRating).toBeDefined();
    expect(mockPrisma.auditLog.create).toHaveBeenCalled();
  });

  // ============================================================
  // 15. Date Filtering with Year and Month
  // ============================================================
  it("Scenario 15: Should support year and month filters accurately in DateRangeUtil", () => {
    const parsed = DateRangeUtil.parseAndValidateDateRange(
      undefined,
      undefined,
      2026,
      8,
    );

    expect(parsed.startDate.getUTCFullYear()).toBe(2026);
    expect(parsed.startDate.getUTCMonth()).toBe(7); // 0-indexed: 7 is August
    expect(parsed.startDate.getUTCDate()).toBe(1);
    expect(parsed.endDate.getUTCDate()).toBe(31);
  });

  // ============================================================
  // 16. Pagination Math
  // ============================================================
  it("Scenario 16: Should compute skip offset and limit correctly", async () => {
    const res = await reportsService.getAttendanceReport({
      startDate: "2026-08-01",
      endDate: "2026-08-31",
      page: 2,
      limit: 5,
    });

    expect(res.meta.page).toBe(2);
    expect(res.meta.limit).toBe(5);
    expect(res.meta.totalPages).toBe(4);
  });

  // ============================================================
  // 17. Sorting Whitelist
  // ============================================================
  it("Scenario 17: Should fallback to safe default when unapproved sort field is supplied", async () => {
    await reportsService.getAttendanceReport({
      startDate: "2026-08-01",
      endDate: "2026-08-31",
      sortBy: "UNAUTHORIZED_SQL_INJECTION; DROP TABLE users;",
    });

    expect(mockPrisma.attendanceRecord.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        orderBy: { date: "desc" },
      }),
    );
  });

  // ============================================================
  // 18. Invalid Date Range Rejection
  // ============================================================
  it("Scenario 18: Should reject when startDate is after endDate", () => {
    expect(() =>
      DateRangeUtil.parseAndValidateDateRange("2026-08-31", "2026-08-01"),
    ).toThrow(BadRequestException);
  });

  // ============================================================
  // 19. Excessive Date Range Rejection (> 366 days)
  // ============================================================
  it("Scenario 19: Should reject date range exceeding 366 days", () => {
    expect(() =>
      DateRangeUtil.parseAndValidateDateRange("2024-01-01", "2026-01-01"),
    ).toThrow(BadRequestException);
  });

  // ============================================================
  // 20. Employee Self-Report
  // ============================================================
  it("Scenario 20: Should return isolated employee self-report for authenticated user", async () => {
    const res = await reportsService.getEmployeeSelfReport("user-1", {
      startDate: "2026-08-01",
      endDate: "2026-08-31",
    });

    expect(res.employee.id).toBe("emp-1");
    expect(res.employee.employeeCode).toBe("CW-100");
    expect(res.attendance.attendanceRate).toBeDefined();
    expect(res.requests).toBeDefined();
    expect(res.payroll?.netSalary).toBe(21000);
  });

  // ============================================================
  // 21. Employee Self-Report Profile Missing
  // ============================================================
  it("Scenario 21: Should throw NotFoundException if employee profile does not exist", async () => {
    mockPrisma.employeeProfile.findUnique.mockResolvedValueOnce(null);

    await expect(
      reportsService.getEmployeeSelfReport("unknown-user", {}),
    ).rejects.toThrow(NotFoundException);
  });

  // ============================================================
  // 22. IDOR Protection (Scoped Query)
  // ============================================================
  it("Scenario 22: IDOR Protection — Self-report strictly binds to authenticated userId", async () => {
    await reportsService.getEmployeeSelfReport("user-1", {});

    expect(mockPrisma.employeeProfile.findUnique).toHaveBeenCalledWith({
      where: { userId: "user-1" },
      select: expect.any(Object),
    });
  });

  // ============================================================
  // 23. CSV Export Structure
  // ============================================================
  it("Scenario 23: Should generate valid CSV structure with appropriate headers", async () => {
    const csv = await reportsService.exportAttendanceCsv(
      { startDate: "2026-08-01", endDate: "2026-08-31" },
      { id: "admin-1" },
    );

    expect(csv).toContain('"Date","Employee Code","Employee Name"');
    expect(csv).toContain('"Omar Hassan"');
    expect(mockPrisma.auditLog.create).toHaveBeenCalled();
  });

  // ============================================================
  // 24. CSV Formula Injection Sanitization
  // ============================================================
  it("Scenario 24: Should neutralize formula injection triggers in CSV export", () => {
    expect(CsvExporterUtil.sanitizeCell("=SUM(A1:A10)")).toBe(
      '"\'=SUM(A1:A10)"',
    );
    expect(CsvExporterUtil.sanitizeCell("+cmd|' /C calc'")).toBe(
      "\"'+cmd|' /C calc'\"",
    );
    expect(CsvExporterUtil.sanitizeCell("-100")).toBe('"\'-100"');
    expect(CsvExporterUtil.sanitizeCell("@SUM")).toBe('"\'@SUM"');
    expect(CsvExporterUtil.sanitizeCell("Normal Text")).toBe('"Normal Text"');
    expect(CsvExporterUtil.sanitizeCell(null)).toBe('""');
  });

  // ============================================================
  // 25. Audit Log Creation for Sensitive Reports
  // ============================================================
  it("Scenario 25: Should record audit log entry for sensitive report access", async () => {
    await reportsService.getPayrollAnalytics({}, { id: "hr-admin-1" });

    expect(mockPrisma.auditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        userId: "hr-admin-1",
        action: AuditAction.CREATE,
        entity: "REPORT",
        entityId: "PAYROLL_REPORT",
      }),
    });
  });

  // ============================================================
  // 26. Zero Records Handling (No NaN or division by zero)
  // ============================================================
  it("Scenario 26: Should handle zero records gracefully without NaN", async () => {
    mockPrisma.attendanceRecord.aggregate.mockResolvedValueOnce({
      _sum: {
        lateMinutes: null,
        earlyLeaveMinutes: null,
        workDurationMinutes: null,
      },
      _avg: {
        lateMinutes: null,
        earlyLeaveMinutes: null,
        workDurationMinutes: null,
      },
      _count: { id: 0 },
    });
    mockPrisma.attendanceRecord.groupBy.mockResolvedValueOnce([]);

    const res = await reportsService.getAttendanceReport({
      startDate: "2026-08-01",
      endDate: "2026-08-31",
    });

    expect(res.summary.averageLateMinutes).toBe(0);
    expect(res.summary.averageEarlyLeaveMinutes).toBe(0);
    expect(res.summary.attendanceRate).toBe(0);
  });

  // ============================================================
  // 27. Expected Working Days Computation
  // ============================================================
  it("Scenario 27: Should calculate exact working days skipping weekends", () => {
    // 2026-08-01 (Sat) to 2026-08-07 (Fri) has 5 working days: Sun, Mon, Tue, Wed, Thu (indices 0,1,2,3,4)
    const start = new Date("2026-08-01T00:00:00Z");
    const end = new Date("2026-08-07T23:59:59Z");
    const workingDays = DateRangeUtil.calculateExpectedWorkingDays(
      start,
      end,
      [0, 1, 2, 3, 4],
    );

    expect(workingDays).toBe(5);
  });

  // ============================================================
  // 28. Department Scoped Filtering
  // ============================================================
  it("Scenario 28: Should apply department filter when provided", async () => {
    await reportsService.getAttendanceReport({
      department: "Engineering",
      startDate: "2026-08-01",
      endDate: "2026-08-31",
    });

    expect(mockPrisma.attendanceRecord.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          employee: { department: "Engineering" },
        }),
      }),
    );
  });

  // ============================================================
  // 29. Workplace Scoped Filtering
  // ============================================================
  it("Scenario 29: Should apply workplace filter when provided", async () => {
    await reportsService.getAttendanceReport({
      workplaceId: "wp-1",
      startDate: "2026-08-01",
      endDate: "2026-08-31",
    });

    expect(mockPrisma.attendanceRecord.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          workplaceId: "wp-1",
        }),
      }),
    );
  });

  // ============================================================
  // 30. Status Filtered Attendance Report
  // ============================================================
  it("Scenario 30: Should apply attendance status filter when provided", async () => {
    await reportsService.getAttendanceReport({
      status: AttendanceStatus.LATE,
      startDate: "2026-08-01",
      endDate: "2026-08-31",
    });

    expect(mockPrisma.attendanceRecord.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          status: AttendanceStatus.LATE,
        }),
      }),
    );
  });

  // ============================================================
  // 31. Security Rating Assessment
  // ============================================================
  it("Scenario 31: Should evaluate security rating properly in security analytics", async () => {
    const res = await reportsService.getSecurityAnalytics(
      { startDate: "2026-08-01", endDate: "2026-08-31" },
      { id: "admin-1" },
    );

    expect(["OPTIMAL", "MODERATE_RISK", "HIGH_RISK"]).toContain(
      res.summary.securityRating,
    );
  });

  // ============================================================
  // 32. Multi-column CSV Generator
  // ============================================================
  it("Scenario 32: Should generate multi-row CSV with safe quotation and delimiter formatting", () => {
    const headers = [
      { key: "id", label: "ID" },
      { key: "name", label: "Full Name" },
    ];
    const rows = [
      { id: "1", name: 'John "The Chief" Doe' },
      { id: "2", name: "Jane Smith" },
    ];

    const result = CsvExporterUtil.generateCsv(headers, rows);
    expect(result).toContain('"ID","Full Name"');
    expect(result).toContain('"1","John ""The Chief"" Doe"');
    expect(result).toContain('"2","Jane Smith"');
  });

  // ============================================================
  // 33. Audit Log Failure Resilience
  // ============================================================
  it("Scenario 33: Should not throw error when audit logging encounters an exception", async () => {
    mockPrisma.auditLog.create.mockRejectedValueOnce(
      new Error("DB Connection Error"),
    );

    // Should still resolve successfully and log warning internally
    const res = await reportsService.getPayrollAnalytics({}, { id: "admin-1" });
    expect(res).toBeDefined();
  });
});
