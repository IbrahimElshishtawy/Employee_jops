import { Injectable, Logger, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  Prisma,
  AttendanceStatus,
  RequestStatus,
  RequestType,
  InstallmentStatus,
  PayrollLineItemType,
  UserStatus,
} from "@prisma/client";

export interface CalculatedPayrollResult {
  employeeId: string;
  basicSalary: Prisma.Decimal;
  allowances: Prisma.Decimal;
  grossSalary: Prisma.Decimal;
  totalDeductions: Prisma.Decimal;
  netSalary: Prisma.Decimal;
  lineItems: {
    type: PayrollLineItemType;
    name: string;
    description?: string;
    amount: Prisma.Decimal;
    isDeduction: boolean;
    source?: string;
    sourceId?: string;
  }[];
  advanceInstallmentIds: string[];
}

@Injectable()
export class PayrollCalculatorService {
  private readonly logger = new Logger(PayrollCalculatorService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Calculates full payroll itemization and net salary for a given employee in a payroll period
   */
  async calculateEmployeePayroll(
    employeeId: string,
    periodStartDate: Date,
    periodEndDate: Date,
    prismaClient: any = this.prisma,
  ): Promise<CalculatedPayrollResult> {
    // 1. Resolve Salary Profile
    let salaryProfile = await prismaClient.salaryProfile.findUnique({
      where: { employeeId },
    });

    // Fallback: If no dedicated SalaryProfile exists, check EmployeeProfile baseSalary
    if (!salaryProfile) {
      const employee = await prismaClient.employeeProfile.findUnique({
        where: { id: employeeId },
      });
      if (!employee) {
        throw new NotFoundException(`Employee profile ${employeeId} not found`);
      }
      const baseSalaryDecimal =
        employee.baseSalary || new Prisma.Decimal(10000);
      salaryProfile = {
        basicSalary: baseSalaryDecimal,
        allowances: new Prisma.Decimal(0),
        currency: "EGP",
        status: UserStatus.ACTIVE,
      };
    }

    const basicSalary = new Prisma.Decimal(salaryProfile.basicSalary);
    const allowances = new Prisma.Decimal(salaryProfile.allowances || 0);

    const lineItems: CalculatedPayrollResult["lineItems"] = [];
    const advanceInstallmentIds: string[] = [];

    // Line Item: Basic Salary
    lineItems.push({
      type: PayrollLineItemType.BASIC_SALARY,
      name: "Basic Monthly Salary",
      description: `Contractual monthly base pay (${salaryProfile.currency || "EGP"})`,
      amount: basicSalary,
      isDeduction: false,
      source: "SALARY_PROFILE",
    });

    // Line Item: Allowances
    if (allowances.greaterThan(0)) {
      lineItems.push({
        type: PayrollLineItemType.ALLOWANCE,
        name: "Fixed Allowances",
        description: "Monthly fixed allowances (transportation, housing, etc.)",
        amount: allowances,
        isDeduction: false,
        source: "SALARY_PROFILE",
      });
    }

    // Rate calculations based on standard 30 days, 8 hours/day
    const dailyRate = basicSalary.dividedBy(30);
    const hourlyRate = dailyRate.dividedBy(8);
    const minuteRate = hourlyRate.dividedBy(60);

    // 2. Attendance Anomalies (Late arrival, Unexcused Absence, Early leave)
    const attendanceRecords = await prismaClient.attendanceRecord.findMany({
      where: {
        employeeId,
        date: {
          gte: periodStartDate,
          lte: periodEndDate,
        },
      },
    });

    let totalLateMinutes = 0;
    let totalEarlyMinutes = 0;
    let unexcusedAbsentDays = 0;

    for (const record of attendanceRecords) {
      const isExcused =
        record.notes &&
        (record.notes.includes("excused") || record.notes.includes("Approved"));

      if (!isExcused) {
        if (record.status === AttendanceStatus.ABSENT) {
          unexcusedAbsentDays += 1;
        } else {
          if (record.lateMinutes && record.lateMinutes > 0) {
            totalLateMinutes += record.lateMinutes;
          }
          if (record.earlyLeaveMinutes && record.earlyLeaveMinutes > 0) {
            totalEarlyMinutes += record.earlyLeaveMinutes;
          }
        }
      }
    }

    if (unexcusedAbsentDays > 0) {
      const amount = dailyRate.times(unexcusedAbsentDays).toDecimalPlaces(2);
      lineItems.push({
        type: PayrollLineItemType.ABSENCE_DEDUCTION,
        name: "Unexcused Absence Deduction",
        description: `${unexcusedAbsentDays} unexcused absence day(s) during period`,
        amount,
        isDeduction: true,
        source: "ATTENDANCE",
      });
    }

    if (totalLateMinutes > 0) {
      const amount = minuteRate.times(totalLateMinutes).toDecimalPlaces(2);
      if (amount.greaterThan(0)) {
        lineItems.push({
          type: PayrollLineItemType.LATE_DEDUCTION,
          name: "Lateness Penalty Deduction",
          description: `${totalLateMinutes} unexcused late minutes during period`,
          amount,
          isDeduction: true,
          source: "ATTENDANCE",
        });
      }
    }

    if (totalEarlyMinutes > 0) {
      const amount = minuteRate.times(totalEarlyMinutes).toDecimalPlaces(2);
      if (amount.greaterThan(0)) {
        lineItems.push({
          type: PayrollLineItemType.EARLY_LEAVE_DEDUCTION,
          name: "Early Leave Deduction",
          description: `${totalEarlyMinutes} unexcused early departure minutes during period`,
          amount,
          isDeduction: true,
          source: "ATTENDANCE",
        });
      }
    }

    // 3. Approved Request Effects (e.g. UNPAID_LEAVE)
    const unpaidLeaveRequests = await prismaClient.request.findMany({
      where: {
        employeeId,
        type: RequestType.UNPAID_LEAVE,
        status: RequestStatus.APPROVED,
        startDate: { lte: periodEndDate },
        endDate: { gte: periodStartDate },
      },
    });

    for (const req of unpaidLeaveRequests) {
      const reqStart =
        req.startDate < periodStartDate ? periodStartDate : req.startDate;
      const reqEnd = req.endDate > periodEndDate ? periodEndDate : req.endDate;
      const diffMs = reqEnd.getTime() - reqStart.getTime();
      const unpaidDays = Math.floor(diffMs / (1000 * 60 * 60 * 24)) + 1;

      if (unpaidDays > 0) {
        const amount = dailyRate.times(unpaidDays).toDecimalPlaces(2);
        lineItems.push({
          type: PayrollLineItemType.UNPAID_LEAVE_DEDUCTION,
          name: "Approved Unpaid Leave Deduction",
          description: `${unpaidDays} day(s) unpaid leave (${req.reason})`,
          amount,
          isDeduction: true,
          source: "REQUEST",
          sourceId: req.id,
        });
      }
    }

    // 4. Advance Installments Due in this Period
    const dueInstallments = await prismaClient.advanceInstallment.findMany({
      where: {
        advance: {
          employeeId,
          status: { in: ["APPROVED", "ACTIVE", "PARTIALLY_PAID"] },
        },
        status: {
          in: [InstallmentStatus.PENDING, InstallmentStatus.PARTIALLY_PAID],
        },
        dueDate: {
          gte: periodStartDate,
          lte: periodEndDate,
        },
      },
      include: {
        advance: true,
      },
    });

    for (const inst of dueInstallments) {
      const deductionAmount = new Prisma.Decimal(inst.remainingAmount);
      if (deductionAmount.greaterThan(0)) {
        lineItems.push({
          type: PayrollLineItemType.ADVANCE_INSTALLMENT,
          name: `Salary Advance Installment #${inst.installmentNumber}`,
          description: `Installment deduction for advance ${inst.advance.reason}`,
          amount: deductionAmount,
          isDeduction: true,
          source: "ADVANCE",
          sourceId: inst.id,
        });
        advanceInstallmentIds.push(inst.id);
      }
    }

    // 5. Manual Financial Deductions
    const manualDeductions = await prismaClient.financialDeduction.findMany({
      where: {
        employeeId,
        effectiveDate: {
          gte: periodStartDate,
          lte: periodEndDate,
        },
      },
    });

    for (const ded of manualDeductions) {
      lineItems.push({
        type: PayrollLineItemType.MANUAL_DEDUCTION,
        name: `Deduction (${ded.type})`,
        description: ded.reason,
        amount: new Prisma.Decimal(ded.amount),
        isDeduction: true,
        source: "MANUAL_DEDUCTION",
        sourceId: ded.id,
      });
    }

    // 6. Aggregate Totals
    let grossSalary = new Prisma.Decimal(0);
    let totalDeductions = new Prisma.Decimal(0);

    for (const item of lineItems) {
      if (item.isDeduction) {
        totalDeductions = totalDeductions.plus(item.amount);
      } else {
        grossSalary = grossSalary.plus(item.amount);
      }
    }

    grossSalary = grossSalary.toDecimalPlaces(2);
    totalDeductions = totalDeductions.toDecimalPlaces(2);

    let netSalary = grossSalary.minus(totalDeductions).toDecimalPlaces(2);
    if (netSalary.lessThan(0)) {
      netSalary = new Prisma.Decimal(0);
    }

    return {
      employeeId,
      basicSalary,
      allowances,
      grossSalary,
      totalDeductions,
      netSalary,
      lineItems,
      advanceInstallmentIds,
    };
  }
}
