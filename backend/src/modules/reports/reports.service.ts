import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  AttendanceReportQueryDto,
  BaseReportQueryDto,
  DeductionReportQueryDto,
  AdvanceReportQueryDto,
  ExportReportQueryDto,
  PayrollReportQueryDto,
  RequestReportQueryDto,
  SortOrder,
} from "./dto";
import { DateRangeUtil } from "./utils/date-range.util";
import { CsvExporterUtil } from "./utils/csv-exporter.util";
import {
  AttendanceStatus,
  AuditAction,
  DeductionType,
  Prisma,
  RequestStatus,
  RequestType,
  UserStatus,
} from "@prisma/client";

@Injectable()
export class ReportsService {
  private readonly logger = new Logger(ReportsService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ============================================================
  // 1. DASHBOARD SUMMARY KPIs
  // ============================================================

  async getDashboardSummary() {
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);

    const firstDayOfMonth = new Date(
      Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), 1),
    );
    const lastDayOfMonth = new Date(
      Date.UTC(today.getUTCFullYear(), today.getUTCMonth() + 1, 0, 23, 59, 59),
    );

    const [
      totalEmployees,
      activeUsers,
      inactiveUsers,
      todayRecords,
      pendingRequests,
      pendingAdvances,
      activeWorkplaces,
      monthlyPayrollSum,
      monthlyDeductionsSum,
      monthlyAdvancesSum,
    ] = await Promise.all([
      this.prisma.employeeProfile.count(),
      this.prisma.user.count({ where: { status: UserStatus.ACTIVE } }),
      this.prisma.user.count({
        where: { status: { in: [UserStatus.INACTIVE, UserStatus.SUSPENDED] } },
      }),
      this.prisma.attendanceRecord.findMany({
        where: {
          date: {
            gte: today,
            lt: tomorrow,
          },
        },
        select: {
          status: true,
          checkInTime: true,
          checkOutTime: true,
          lateMinutes: true,
        },
      }),
      this.prisma.request.count({ where: { status: RequestStatus.PENDING } }),
      this.prisma.financialAdvance.count({ where: { status: "PENDING" } }),
      this.prisma.workplace.count({ where: { isActive: true } }),
      this.prisma.payrollRecord.aggregate({
        _sum: { netSalary: true, grossSalary: true },
        where: {
          payrollPeriod: {
            startDate: { gte: firstDayOfMonth },
            endDate: { lte: lastDayOfMonth },
          },
        },
      }),
      this.prisma.financialDeduction.aggregate({
        _sum: { amount: true },
        where: {
          effectiveDate: { gte: firstDayOfMonth, lte: lastDayOfMonth },
        },
      }),
      this.prisma.financialAdvance.aggregate({
        _sum: { amount: true, paidAmount: true },
        where: {
          createdAt: { gte: firstDayOfMonth, lte: lastDayOfMonth },
        },
      }),
    ]);

    const presentCount = todayRecords.filter(
      (r) => r.status === AttendanceStatus.PRESENT,
    ).length;
    const lateCount = todayRecords.filter(
      (r) => r.status === AttendanceStatus.LATE || (r.lateMinutes || 0) > 0,
    ).length;
    const absentCount = todayRecords.filter(
      (r) => r.status === AttendanceStatus.ABSENT,
    ).length;
    const currentlyCheckedIn = todayRecords.filter(
      (r) => r.checkInTime !== null && r.checkOutTime === null,
    ).length;

    return {
      employees: {
        total: totalEmployees,
        active: activeUsers,
        inactive: inactiveUsers,
      },
      todayAttendance: {
        totalRecords: todayRecords.length,
        present: presentCount,
        late: lateCount,
        absent: absentCount,
        currentlyCheckedIn,
      },
      pendingActions: {
        requests: pendingRequests,
        advances: pendingAdvances,
      },
      workplaces: {
        active: activeWorkplaces,
      },
      monthlyFinancials: {
        month: today.getUTCMonth() + 1,
        year: today.getUTCFullYear(),
        netPayroll: monthlyPayrollSum._sum.netSalary || 0,
        grossPayroll: monthlyPayrollSum._sum.grossSalary || 0,
        totalDeductions: monthlyDeductionsSum._sum.amount || 0,
        totalAdvances: monthlyAdvancesSum._sum.amount || 0,
      },
    };
  }

  // ============================================================
  // 2. ATTENDANCE ANALYTICS & REPORT
  // ============================================================

  async getAttendanceReport(query: AttendanceReportQueryDto, currentUser?: any) {
    const { startDate, endDate } = DateRangeUtil.parseAndValidateDateRange(
      query.startDate,
      query.endDate,
      query.year,
      query.month,
    );

    const where: Prisma.AttendanceRecordWhereInput = {
      date: {
        gte: startDate,
        lte: endDate,
      },
    };

    if (query.employeeId) {
      where.employeeId = query.employeeId;
    }
    if (query.department) {
      where.employee = { department: query.department };
    }
    if (query.workplaceId) {
      where.workplaceId = query.workplaceId;
    }
    if (query.status) {
      where.status = query.status;
    }

    // Whitelist sorting fields
    const allowedSortFields = [
      "date",
      "createdAt",
      "lateMinutes",
      "earlyLeaveMinutes",
      "workDurationMinutes",
      "status",
    ];
    const sortBy = allowedSortFields.includes(query.sortBy || "")
      ? query.sortBy!
      : "date";
    const sortOrder = query.sortOrder || SortOrder.DESC;

    const [total, records, aggregations, totalEmployeesCount] =
      await Promise.all([
        this.prisma.attendanceRecord.count({ where }),
        this.prisma.attendanceRecord.findMany({
          where,
          skip: query.skip,
          take: query.limit,
          orderBy: { [sortBy]: sortOrder },
          include: {
            employee: {
              select: {
                id: true,
                employeeCode: true,
                firstName: true,
                lastName: true,
                department: true,
                jobTitle: true,
              },
            },
            workplace: {
              select: {
                id: true,
                name: true,
                code: true,
              },
            },
          },
        }),
        this.prisma.attendanceRecord.aggregate({
          where,
          _sum: {
            lateMinutes: true,
            earlyLeaveMinutes: true,
            workDurationMinutes: true,
          },
          _avg: {
            lateMinutes: true,
            earlyLeaveMinutes: true,
            workDurationMinutes: true,
          },
          _count: {
            id: true,
          },
        }),
        this.prisma.employeeProfile.count({
          where: query.department ? { department: query.department } : {},
        }),
      ]);

    // Grouping by status
    const statusCounts = await this.prisma.attendanceRecord.groupBy({
      by: ["status"],
      where,
      _count: { id: true },
    });

    const statusMap: Record<string, number> = {};
    for (const sc of statusCounts) {
      statusMap[sc.status] = sc._count.id;
    }

    const presentDays = statusMap[AttendanceStatus.PRESENT] || 0;
    const lateDays = statusMap[AttendanceStatus.LATE] || 0;
    const absentDays = statusMap[AttendanceStatus.ABSENT] || 0;
    const earlyLeaveDays = statusMap[AttendanceStatus.EARLY_LEAVE] || 0;
    const onLeaveDays = statusMap[AttendanceStatus.ON_LEAVE] || 0;

    const expectedWorkingDays = DateRangeUtil.calculateExpectedWorkingDays(
      startDate,
      endDate,
    );
    const denominator = (query.employeeId ? 1 : totalEmployeesCount) * expectedWorkingDays;
    const attendanceRate =
      denominator > 0
        ? Number((((presentDays + lateDays + onLeaveDays) / denominator) * 100).toFixed(2))
        : 100;

    return {
      summary: {
        startDate,
        endDate,
        expectedWorkingDays,
        totalRecords: total,
        presentDays,
        lateDays,
        absentDays,
        earlyLeaveDays,
        onLeaveDays,
        attendanceRate,
        totalLateMinutes: aggregations._sum.lateMinutes || 0,
        averageLateMinutes: Number(
          (aggregations._avg.lateMinutes || 0).toFixed(1),
        ),
        totalEarlyLeaveMinutes: aggregations._sum.earlyLeaveMinutes || 0,
        averageEarlyLeaveMinutes: Number(
          (aggregations._avg.earlyLeaveMinutes || 0).toFixed(1),
        ),
      },
      data: records,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        totalPages: Math.ceil(total / query.limit),
      },
    };
  }

  // ============================================================
  // 3. LATE ANALYTICS
  // ============================================================

  async getLateAnalytics(query: AttendanceReportQueryDto) {
    const { startDate, endDate } = DateRangeUtil.parseAndValidateDateRange(
      query.startDate,
      query.endDate,
      query.year,
      query.month,
    );

    const where: Prisma.AttendanceRecordWhereInput = {
      date: { gte: startDate, lte: endDate },
      OR: [{ status: AttendanceStatus.LATE }, { lateMinutes: { gt: 0 } }],
    };

    if (query.department) {
      where.employee = { department: query.department };
    }
    if (query.workplaceId) {
      where.workplaceId = query.workplaceId;
    }

    const [lateRecords, agg] = await Promise.all([
      this.prisma.attendanceRecord.findMany({
        where,
        select: {
          employeeId: true,
          lateMinutes: true,
          workplaceId: true,
          employee: {
            select: {
              firstName: true,
              lastName: true,
              employeeCode: true,
              department: true,
            },
          },
          workplace: {
            select: { name: true },
          },
        },
      }),
      this.prisma.attendanceRecord.aggregate({
        where,
        _sum: { lateMinutes: true },
        _avg: { lateMinutes: true },
        _count: { id: true },
      }),
    ]);

    // Aggregate by employee
    const employeeMap = new Map<
      string,
      {
        employeeId: string;
        employeeName: string;
        employeeCode: string;
        department: string;
        occurrences: number;
        totalLateMinutes: number;
      }
    >();

    const deptMap = new Map<string, { occurrences: number; totalMinutes: number }>();
    const workplaceMap = new Map<string, { occurrences: number; totalMinutes: number }>();

    for (const rec of lateRecords) {
      const mins = rec.lateMinutes || 0;
      // Employee aggregation
      const emp = employeeMap.get(rec.employeeId) || {
        employeeId: rec.employeeId,
        employeeName: `${rec.employee.firstName} ${rec.employee.lastName}`,
        employeeCode: rec.employee.employeeCode,
        department: rec.employee.department,
        occurrences: 0,
        totalLateMinutes: 0,
      };
      emp.occurrences += 1;
      emp.totalLateMinutes += mins;
      employeeMap.set(rec.employeeId, emp);

      // Department aggregation
      const d = deptMap.get(rec.employee.department) || {
        occurrences: 0,
        totalMinutes: 0,
      };
      d.occurrences += 1;
      d.totalMinutes += mins;
      deptMap.set(rec.employee.department, d);

      // Workplace aggregation
      const wpName = rec.workplace?.name || "Unassigned";
      const w = workplaceMap.get(wpName) || {
        occurrences: 0,
        totalMinutes: 0,
      };
      w.occurrences += 1;
      w.totalMinutes += mins;
      workplaceMap.set(wpName, w);
    }

    const topLateEmployees = Array.from(employeeMap.values())
      .sort((a, b) => b.totalLateMinutes - a.totalLateMinutes)
      .slice(0, 10);

    const departmentDistribution = Array.from(deptMap.entries()).map(
      ([department, stats]) => ({
        department,
        occurrences: stats.occurrences,
        totalMinutes: stats.totalMinutes,
        avgMinutes: Number((stats.totalMinutes / stats.occurrences).toFixed(1)),
      }),
    );

    const workplaceDistribution = Array.from(workplaceMap.entries()).map(
      ([workplace, stats]) => ({
        workplace,
        occurrences: stats.occurrences,
        totalMinutes: stats.totalMinutes,
        avgMinutes: Number((stats.totalMinutes / stats.occurrences).toFixed(1)),
      }),
    );

    return {
      summary: {
        startDate,
        endDate,
        lateEmployeesCount: employeeMap.size,
        lateOccurrences: agg._count.id,
        totalLateMinutes: agg._sum.lateMinutes || 0,
        averageLateMinutes: Number((agg._avg.lateMinutes || 0).toFixed(1)),
      },
      topLateEmployees,
      departmentDistribution,
      workplaceDistribution,
    };
  }

  // ============================================================
  // 4. ABSENCE ANALYTICS
  // ============================================================

  async getAbsenceAnalytics(query: AttendanceReportQueryDto) {
    const { startDate, endDate } = DateRangeUtil.parseAndValidateDateRange(
      query.startDate,
      query.endDate,
      query.year,
      query.month,
    );

    const where: Prisma.AttendanceRecordWhereInput = {
      date: { gte: startDate, lte: endDate },
      status: AttendanceStatus.ABSENT,
    };

    if (query.department) {
      where.employee = { department: query.department };
    }
    if (query.workplaceId) {
      where.workplaceId = query.workplaceId;
    }

    const [absenceRecords, totalEmployees, approvedLeaveRequests] =
      await Promise.all([
        this.prisma.attendanceRecord.findMany({
          where,
          include: {
            employee: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                employeeCode: true,
                department: true,
              },
            },
            workplace: { select: { name: true } },
          },
        }),
        this.prisma.employeeProfile.count({
          where: query.department ? { department: query.department } : {},
        }),
        this.prisma.request.count({
          where: {
            status: RequestStatus.APPROVED,
            type: {
              in: [
                RequestType.ANNUAL_LEAVE,
                RequestType.SICK_LEAVE,
                RequestType.UNPAID_LEAVE,
                RequestType.EMERGENCY_LEAVE,
                RequestType.OFFICIAL_LEAVE,
                RequestType.LEAVE,
                RequestType.ABSENCE,
              ],
            },
            startDate: { lte: endDate },
            endDate: { gte: startDate },
          },
        }),
      ]);

    const totalAbsenceCount = absenceRecords.length;
    const approvedAbsence = Math.min(totalAbsenceCount, approvedLeaveRequests);
    const unapprovedAbsence = Math.max(0, totalAbsenceCount - approvedAbsence);

    const expectedWorkingDays = DateRangeUtil.calculateExpectedWorkingDays(
      startDate,
      endDate,
    );
    const totalPossibleWorkingDays = (totalEmployees || 1) * (expectedWorkingDays || 1);
    const absenceRate = Number(
      ((totalAbsenceCount / totalPossibleWorkingDays) * 100).toFixed(2),
    );

    // Department & Workplace breakdowns
    const deptMap = new Map<string, number>();
    const wpMap = new Map<string, number>();
    const empMap = new Map<
      string,
      { employeeName: string; employeeCode: string; department: string; count: number }
    >();

    for (const rec of absenceRecords) {
      deptMap.set(
        rec.employee.department,
        (deptMap.get(rec.employee.department) || 0) + 1,
      );
      const wpName = rec.workplace?.name || "Unassigned";
      wpMap.set(wpName, (wpMap.get(wpName) || 0) + 1);

      const e = empMap.get(rec.employeeId) || {
        employeeName: `${rec.employee.firstName} ${rec.employee.lastName}`,
        employeeCode: rec.employee.employeeCode,
        department: rec.employee.department,
        count: 0,
      };
      e.count += 1;
      empMap.set(rec.employeeId, e);
    }

    return {
      summary: {
        startDate,
        endDate,
        totalAbsenceCount,
        approvedAbsence,
        unapprovedAbsence,
        absenceRate,
      },
      topAbsentEmployees: Array.from(empMap.values())
        .sort((a, b) => b.count - a.count)
        .slice(0, 10),
      departmentAbsence: Array.from(deptMap.entries()).map(
        ([department, count]) => ({ department, count }),
      ),
      workplaceAbsence: Array.from(wpMap.entries()).map(([workplace, count]) => ({
        workplace,
        count,
      })),
    };
  }

  // ============================================================
  // 5. REQUEST ANALYTICS
  // ============================================================

  async getRequestAnalytics(query: RequestReportQueryDto) {
    const { startDate, endDate } = DateRangeUtil.parseAndValidateDateRange(
      query.startDate,
      query.endDate,
      query.year,
      query.month,
    );

    const where: Prisma.RequestWhereInput = {
      createdAt: { gte: startDate, lte: endDate },
    };

    if (query.employeeId) {
      where.employeeId = query.employeeId;
    }
    if (query.department) {
      where.employee = { department: query.department };
    }
    if (query.type) {
      where.type = query.type;
    }
    if (query.status) {
      where.status = query.status;
    }

    const [totalRequests, requests, byTypeGrouping, byStatusGrouping] =
      await Promise.all([
        this.prisma.request.count({ where }),
        this.prisma.request.findMany({
          where,
          select: {
            id: true,
            status: true,
            type: true,
            createdAt: true,
            reviewedAt: true,
          },
        }),
        this.prisma.request.groupBy({
          by: ["type"],
          where,
          _count: { id: true },
        }),
        this.prisma.request.groupBy({
          by: ["status"],
          where,
          _count: { id: true },
        }),
      ]);

    const statusMap: Record<string, number> = {};
    for (const s of byStatusGrouping) {
      statusMap[s.status] = s._count.id;
    }

    const pending = statusMap[RequestStatus.PENDING] || 0;
    const approved = statusMap[RequestStatus.APPROVED] || 0;
    const rejected = statusMap[RequestStatus.REJECTED] || 0;
    const cancelled = statusMap[RequestStatus.CANCELLED] || 0;

    const resolved = approved + rejected;
    const approvalRate =
      resolved > 0 ? Number(((approved / resolved) * 100).toFixed(2)) : 0;
    const rejectionRate =
      resolved > 0 ? Number(((rejected / resolved) * 100).toFixed(2)) : 0;

    // Calculate processing durations in hours
    let totalProcessingHours = 0;
    let reviewedCount = 0;

    for (const req of requests) {
      if (req.reviewedAt && req.createdAt) {
        const diffMs =
          new Date(req.reviewedAt).getTime() - new Date(req.createdAt).getTime();
        const hours = diffMs / (1000 * 60 * 60);
        if (hours >= 0) {
          totalProcessingHours += hours;
          reviewedCount++;
        }
      }
    }

    const averageProcessingDurationHours =
      reviewedCount > 0
        ? Number((totalProcessingHours / reviewedCount).toFixed(2))
        : 0;

    return {
      summary: {
        startDate,
        endDate,
        totalRequests,
        pending,
        approved,
        rejected,
        cancelled,
        approvalRate,
        rejectionRate,
        averageProcessingDurationHours,
      },
      byType: byTypeGrouping.map((t) => ({
        type: t.type,
        count: t._count.id,
      })),
      byStatus: byStatusGrouping.map((s) => ({
        status: s.status,
        count: s._count.id,
      })),
    };
  }

  // ============================================================
  // 6. PAYROLL & FINANCIAL ANALYTICS
  // ============================================================

  async getPayrollAnalytics(query: PayrollReportQueryDto, currentUser?: any) {
    // Log audit for sensitive payroll reports
    await this.logReportAccess(currentUser?.id, "PAYROLL_REPORT", query);

    const where: Prisma.PayrollRecordWhereInput = {};

    if (query.payrollPeriodId) {
      where.payrollPeriodId = query.payrollPeriodId;
    }
    if (query.department) {
      where.employee = { department: query.department };
    }
    if (query.workplaceId) {
      where.employee = { workplaceId: query.workplaceId };
    }
    if (query.status) {
      where.payrollPeriod = { status: query.status };
    }

    const [records, agg, periodList] = await Promise.all([
      this.prisma.payrollRecord.findMany({
        where,
        select: {
          basicSalary: true,
          allowances: true,
          grossSalary: true,
          totalDeductions: true,
          netSalary: true,
          employee: {
            select: { department: true, workplaceId: true },
          },
          payrollPeriod: {
            select: { id: true, name: true, startDate: true, endDate: true },
          },
        },
      }),
      this.prisma.payrollRecord.aggregate({
        where,
        _sum: {
          basicSalary: true,
          allowances: true,
          grossSalary: true,
          totalDeductions: true,
          netSalary: true,
        },
        _avg: {
          netSalary: true,
          grossSalary: true,
        },
        _count: { id: true },
      }),
      this.prisma.payrollPeriod.findMany({
        orderBy: { startDate: "desc" },
        take: 12,
        select: {
          id: true,
          name: true,
          status: true,
          _count: { select: { payrollRecords: true } },
        },
      }),
    ]);

    // Department grouping
    const deptMap = new Map<
      string,
      { count: number; gross: number; deductions: number; net: number }
    >();

    for (const r of records) {
      const d = deptMap.get(r.employee.department) || {
        count: 0,
        gross: 0,
        deductions: 0,
        net: 0,
      };
      d.count += 1;
      d.gross += Number(r.grossSalary);
      d.deductions += Number(r.totalDeductions);
      d.net += Number(r.netSalary);
      deptMap.set(r.employee.department, d);
    }

    return {
      summary: {
        totalRecords: agg._count.id,
        grossPayroll: agg._sum.grossSalary || 0,
        totalDeductions: agg._sum.totalDeductions || 0,
        netPayroll: agg._sum.netSalary || 0,
        averageNetSalary: Number((agg._avg.netSalary || 0).toFixed(2)),
        averageGrossSalary: Number((agg._avg.grossSalary || 0).toFixed(2)),
      },
      departmentPayroll: Array.from(deptMap.entries()).map(
        ([department, stats]) => ({
          department,
          employeeCount: stats.count,
          grossPayroll: stats.gross,
          totalDeductions: stats.deductions,
          netPayroll: stats.net,
        }),
      ),
      recentPeriods: periodList,
    };
  }

  // ============================================================
  // 7. DEDUCTION ANALYTICS
  // ============================================================

  async getDeductionAnalytics(query: DeductionReportQueryDto) {
    const { startDate, endDate } = DateRangeUtil.parseAndValidateDateRange(
      query.startDate,
      query.endDate,
      query.year,
      query.month,
    );

    const where: Prisma.FinancialDeductionWhereInput = {
      effectiveDate: { gte: startDate, lte: endDate },
    };

    if (query.type) {
      where.type = query.type;
    }
    if (query.department) {
      where.employee = { department: query.department };
    }
    if (query.employeeId) {
      where.employeeId = query.employeeId;
    }

    const [agg, byType, byDept] = await Promise.all([
      this.prisma.financialDeduction.aggregate({
        where,
        _sum: { amount: true },
        _avg: { amount: true },
        _count: { id: true },
      }),
      this.prisma.financialDeduction.groupBy({
        by: ["type"],
        where,
        _sum: { amount: true },
        _count: { id: true },
      }),
      this.prisma.financialDeduction.findMany({
        where,
        select: {
          amount: true,
          employee: { select: { department: true } },
        },
      }),
    ]);

    const deptMap = new Map<string, { count: number; sum: number }>();
    for (const d of byDept) {
      const cur = deptMap.get(d.employee.department) || { count: 0, sum: 0 };
      cur.count += 1;
      cur.sum += Number(d.amount);
      deptMap.set(d.employee.department, cur);
    }

    return {
      summary: {
        startDate,
        endDate,
        totalDeductionsCount: agg._count.id,
        totalDeductionAmount: agg._sum.amount || 0,
        averageDeductionAmount: Number((agg._avg.amount || 0).toFixed(2)),
      },
      byType: byType.map((t) => ({
        type: t.type,
        count: t._count.id,
        totalAmount: t._sum.amount || 0,
      })),
      byDepartment: Array.from(deptMap.entries()).map(([department, stat]) => ({
        department,
        count: stat.count,
        totalAmount: stat.sum,
      })),
    };
  }

  // ============================================================
  // 8. SALARY ADVANCE ANALYTICS
  // ============================================================

  async getAdvanceAnalytics(query: AdvanceReportQueryDto) {
    const { startDate, endDate } = DateRangeUtil.parseAndValidateDateRange(
      query.startDate,
      query.endDate,
      query.year,
      query.month,
    );

    const where: Prisma.FinancialAdvanceWhereInput = {
      createdAt: { gte: startDate, lte: endDate },
    };

    if (query.department) {
      where.employee = { department: query.department };
    }
    if (query.employeeId) {
      where.employeeId = query.employeeId;
    }

    const [agg, byStatus] = await Promise.all([
      this.prisma.financialAdvance.aggregate({
        where,
        _sum: {
          amount: true,
          approvedAmount: true,
          paidAmount: true,
          remainingAmount: true,
        },
        _avg: { amount: true },
        _count: { id: true },
      }),
      this.prisma.financialAdvance.groupBy({
        by: ["status"],
        where,
        _count: { id: true },
        _sum: { amount: true },
      }),
    ]);

    return {
      summary: {
        startDate,
        endDate,
        totalRequestedCount: agg._count.id,
        totalRequestedAmount: agg._sum.amount || 0,
        totalApprovedAmount: agg._sum.approvedAmount || 0,
        totalPaidAmount: agg._sum.paidAmount || 0,
        totalOutstandingBalance: agg._sum.remainingAmount || 0,
        averageAdvanceAmount: Number((agg._avg.amount || 0).toFixed(2)),
      },
      byStatus: byStatus.map((s) => ({
        status: s.status,
        count: s._count.id,
        amount: s._sum.amount || 0,
      })),
    };
  }

  // ============================================================
  // 9. EMPLOYEE ANALYTICS
  // ============================================================

  async getEmployeeAnalytics(query: BaseReportQueryDto) {
    const [
      totalEmployees,
      activeEmployees,
      inactiveEmployees,
      byDepartment,
      byWorkplace,
      byJobTitle,
      recentHires,
    ] = await Promise.all([
      this.prisma.employeeProfile.count(),
      this.prisma.user.count({ where: { status: UserStatus.ACTIVE } }),
      this.prisma.user.count({
        where: { status: { in: [UserStatus.INACTIVE, UserStatus.SUSPENDED] } },
      }),
      this.prisma.employeeProfile.groupBy({
        by: ["department"],
        _count: { id: true },
      }),
      this.prisma.employeeProfile.groupBy({
        by: ["workplaceId"],
        _count: { id: true },
      }),
      this.prisma.employeeProfile.groupBy({
        by: ["jobTitle"],
        _count: { id: true },
      }),
      this.prisma.employeeProfile.count({
        where: {
          hireDate: {
            gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
          },
        },
      }),
    ]);

    const workplaceNames = await this.prisma.workplace.findMany({
      select: { id: true, name: true },
    });
    const wpNameMap = new Map(workplaceNames.map((w) => [w.id, w.name]));

    return {
      overview: {
        total: totalEmployees,
        active: activeEmployees,
        inactive: inactiveEmployees,
        newHiresLast30Days: recentHires,
      },
      byDepartment: byDepartment.map((d) => ({
        department: d.department,
        employeeCount: d._count.id,
      })),
      byWorkplace: byWorkplace.map((w) => ({
        workplaceId: w.workplaceId,
        workplaceName: w.workplaceId ? wpNameMap.get(w.workplaceId) || "Unknown" : "Unassigned",
        employeeCount: w._count.id,
      })),
      byJobTitle: byJobTitle.map((j) => ({
        jobTitle: j.jobTitle,
        employeeCount: j._count.id,
      })),
    };
  }

  // ============================================================
  // 10. DEPARTMENT ANALYTICS
  // ============================================================

  async getDepartmentStats() {
    const departments = await this.prisma.employeeProfile.groupBy({
      by: ["department"],
      _count: { id: true },
    });

    const results = [];
    for (const d of departments) {
      const [pendingReqs, presentToday] = await Promise.all([
        this.prisma.request.count({
          where: {
            employee: { department: d.department },
            status: RequestStatus.PENDING,
          },
        }),
        this.prisma.attendanceRecord.count({
          where: {
            employee: { department: d.department },
            date: {
              gte: new Date(new Date().setUTCHours(0, 0, 0, 0)),
            },
            status: AttendanceStatus.PRESENT,
          },
        }),
      ]);

      results.push({
        department: d.department,
        employeeCount: d._count.id,
        todayPresent: presentToday,
        pendingRequests: pendingReqs,
      });
    }

    return results;
  }

  // ============================================================
  // 11. WORKPLACE ANALYTICS
  // ============================================================

  async getWorkplaceAnalytics(query: BaseReportQueryDto) {
    const workplaces = await this.prisma.workplace.findMany({
      select: {
        id: true,
        name: true,
        code: true,
        isActive: true,
        radiusMeters: true,
        _count: {
          select: {
            employees: true,
            attendances: true,
          },
        },
      },
    });

    const workplaceStats = [];
    for (const wp of workplaces) {
      const [geofenceBreaches, manualCorrections] = await Promise.all([
        this.prisma.attendanceRecord.count({
          where: {
            workplaceId: wp.id,
            OR: [
              { isCheckInWithinGeofence: false },
              { isCheckOutWithinGeofence: false },
            ],
          },
        }),
        this.prisma.attendanceRecord.count({
          where: {
            workplaceId: wp.id,
            isManualEntry: true,
          },
        }),
      ]);

      workplaceStats.push({
        id: wp.id,
        name: wp.name,
        code: wp.code,
        isActive: wp.isActive,
        employeeCount: wp._count.employees,
        totalAttendances: wp._count.attendances,
        geofenceBreaches,
        manualCorrections,
      });
    }

    return workplaceStats;
  }

  // ============================================================
  // 12. SECURITY TELEMETRY ANALYTICS
  // ============================================================

  async getSecurityAnalytics(query: BaseReportQueryDto, currentUser?: any) {
    await this.logReportAccess(currentUser?.id, "SECURITY_REPORT", query);

    const { startDate, endDate } = DateRangeUtil.parseAndValidateDateRange(
      query.startDate,
      query.endDate,
      query.year,
      query.month,
    );

    const [
      rejectedEvents,
      suspiciousRecords,
      manualCorrections,
      poorAccuracyEvents,
    ] = await Promise.all([
      this.prisma.attendanceEvent.count({
        where: {
          timestamp: { gte: startDate, lte: endDate },
          eventType: {
            in: [
              "CHECK_IN_REJECTED",
              "CHECK_OUT_REJECTED",
            ] as any,
          },
        },
      }),
      this.prisma.attendanceRecord.count({
        where: {
          date: { gte: startDate, lte: endDate },
          isSuspicious: true,
        },
      }),
      this.prisma.attendanceRecord.count({
        where: {
          date: { gte: startDate, lte: endDate },
          isManualEntry: true,
        },
      }),
      this.prisma.attendanceEvent.count({
        where: {
          timestamp: { gte: startDate, lte: endDate },
          accuracy: { gt: 100 },
        },
      }),
    ]);

    return {
      summary: {
        startDate,
        endDate,
        rejectedAttempts: rejectedEvents,
        suspiciousSignalsCount: suspiciousRecords,
        manualCorrectionsCount: manualCorrections,
        poorAccuracyCount: poorAccuracyEvents,
        securityRating:
          rejectedEvents + suspiciousRecords === 0
            ? "OPTIMAL"
            : rejectedEvents + suspiciousRecords < 10
              ? "MODERATE_RISK"
              : "HIGH_RISK",
      },
    };
  }

  // ============================================================
  // 13. EMPLOYEE SELF REPORT (GET /api/v1/reports/me)
  // ============================================================

  async getEmployeeSelfReport(userId: string, query: BaseReportQueryDto) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { userId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        employeeCode: true,
        department: true,
        jobTitle: true,
      },
    });

    if (!employee) {
      throw new NotFoundException("Employee profile not found for user");
    }

    const { startDate, endDate } = DateRangeUtil.parseAndValidateDateRange(
      query.startDate,
      query.endDate,
      query.year,
      query.month,
    );

    const [attendanceAgg, attendanceByStatus, requests, recentPayroll, advances] =
      await Promise.all([
        this.prisma.attendanceRecord.aggregate({
          where: {
            employeeId: employee.id,
            date: { gte: startDate, lte: endDate },
          },
          _sum: { lateMinutes: true, earlyLeaveMinutes: true, workDurationMinutes: true },
          _count: { id: true },
        }),
        this.prisma.attendanceRecord.groupBy({
          by: ["status"],
          where: {
            employeeId: employee.id,
            date: { gte: startDate, lte: endDate },
          },
          _count: { id: true },
        }),
        this.prisma.request.findMany({
          where: {
            employeeId: employee.id,
            createdAt: { gte: startDate, lte: endDate },
          },
          orderBy: { createdAt: "desc" },
          take: 10,
          select: {
            id: true,
            type: true,
            status: true,
            startDate: true,
            endDate: true,
            reason: true,
          },
        }),
        this.prisma.payrollRecord.findFirst({
          where: { employeeId: employee.id },
          orderBy: { createdAt: "desc" },
          select: {
            basicSalary: true,
            allowances: true,
            grossSalary: true,
            totalDeductions: true,
            netSalary: true,
            payrollPeriod: { select: { name: true } },
          },
        }),
        this.prisma.financialAdvance.findMany({
          where: { employeeId: employee.id },
          orderBy: { createdAt: "desc" },
          take: 5,
          select: {
            id: true,
            amount: true,
            paidAmount: true,
            remainingAmount: true,
            status: true,
          },
        }),
      ]);

    const statusMap: Record<string, number> = {};
    for (const sc of attendanceByStatus) {
      statusMap[sc.status] = sc._count.id;
    }

    const expectedWorkingDays = DateRangeUtil.calculateExpectedWorkingDays(
      startDate,
      endDate,
    );
    const presentDays = statusMap[AttendanceStatus.PRESENT] || 0;
    const lateDays = statusMap[AttendanceStatus.LATE] || 0;
    const onLeaveDays = statusMap[AttendanceStatus.ON_LEAVE] || 0;
    const absentDays = statusMap[AttendanceStatus.ABSENT] || 0;

    const attendanceRate =
      expectedWorkingDays > 0
        ? Number(
            (
              ((presentDays + lateDays + onLeaveDays) / expectedWorkingDays) *
              100
            ).toFixed(2),
          )
        : 100;

    return {
      employee,
      dateRange: { startDate, endDate, expectedWorkingDays },
      attendance: {
        totalRecords: attendanceAgg._count.id,
        presentDays,
        lateDays,
        absentDays,
        onLeaveDays,
        attendanceRate,
        totalLateMinutes: attendanceAgg._sum.lateMinutes || 0,
        totalEarlyLeaveMinutes: attendanceAgg._sum.earlyLeaveMinutes || 0,
        totalWorkHours: Number(
          ((attendanceAgg._sum.workDurationMinutes || 0) / 60).toFixed(1),
        ),
      },
      requests: {
        total: requests.length,
        recent: requests,
      },
      advances: {
        recent: advances,
      },
      payroll: recentPayroll
        ? {
            period: recentPayroll.payrollPeriod.name,
            netSalary: recentPayroll.netSalary,
            grossSalary: recentPayroll.grossSalary,
            deductions: recentPayroll.totalDeductions,
          }
        : null,
    };
  }

  // ============================================================
  // 14. CSV EXPORT
  // ============================================================

  async exportAttendanceCsv(
    query: ExportReportQueryDto,
    currentUser?: any,
  ): Promise<string> {
    await this.logReportAccess(currentUser?.id, "ATTENDANCE_EXPORT", query);

    const { startDate, endDate } = DateRangeUtil.parseAndValidateDateRange(
      query.startDate,
      query.endDate,
      query.year,
      query.month,
    );

    const where: Prisma.AttendanceRecordWhereInput = {
      date: { gte: startDate, lte: endDate },
    };

    if (query.employeeId) {
      where.employeeId = query.employeeId;
    }
    if (query.department) {
      where.employee = { department: query.department };
    }
    if (query.workplaceId) {
      where.workplaceId = query.workplaceId;
    }
    if (query.status) {
      where.status = query.status;
    }

    const records = await this.prisma.attendanceRecord.findMany({
      where,
      orderBy: { date: "asc" },
      take: 5000, // Export cap for safety
      include: {
        employee: {
          select: {
            employeeCode: true,
            firstName: true,
            lastName: true,
            department: true,
            jobTitle: true,
          },
        },
        workplace: { select: { name: true } },
      },
    });

    const headers = [
      { key: "date", label: "Date" },
      { key: "employeeCode", label: "Employee Code" },
      { key: "employeeName", label: "Employee Name" },
      { key: "department", label: "Department" },
      { key: "workplace", label: "Workplace" },
      { key: "status", label: "Status" },
      { key: "checkInTime", label: "Check-In" },
      { key: "checkOutTime", label: "Check-Out" },
      { key: "lateMinutes", label: "Late (Minutes)" },
      { key: "earlyLeaveMinutes", label: "Early Leave (Minutes)" },
      { key: "workDurationMinutes", label: "Work Duration (Minutes)" },
      { key: "isSuspicious", label: "Suspicious" },
      { key: "isManualEntry", label: "Manual Entry" },
    ];

    const rows = records.map((r) => ({
      date: r.date.toISOString().split("T")[0],
      employeeCode: r.employee.employeeCode,
      employeeName: `${r.employee.firstName} ${r.employee.lastName}`,
      department: r.employee.department,
      workplace: r.workplace?.name || "N/A",
      status: r.status,
      checkInTime: r.checkInTime ? r.checkInTime.toISOString() : "",
      checkOutTime: r.checkOutTime ? r.checkOutTime.toISOString() : "",
      lateMinutes: r.lateMinutes || 0,
      earlyLeaveMinutes: r.earlyLeaveMinutes || 0,
      workDurationMinutes: r.workDurationMinutes || 0,
      isSuspicious: r.isSuspicious ? "YES" : "NO",
      isManualEntry: r.isManualEntry ? "YES" : "NO",
    }));

    return CsvExporterUtil.generateCsv(headers, rows);
  }

  // ============================================================
  // 15. AUDIT LOGGING HELPER
  // ============================================================

  private async logReportAccess(
    userId: string | undefined,
    reportType: string,
    queryPayload: any,
  ) {
    if (!userId) return;
    try {
      await this.prisma.auditLog.create({
        data: {
          userId,
          action: AuditAction.CREATE,
          entity: "REPORT",
          entityId: reportType,
          payload: {
            reportType,
            query: queryPayload,
            accessedAt: new Date().toISOString(),
          },
        },
      });
    } catch (err: any) {
      this.logger.warn(`Failed to write report audit log: ${err?.message}`);
    }
  }
}
