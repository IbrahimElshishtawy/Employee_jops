import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  AttendanceStatus,
  Prisma,
  RequestStatus,
  RequestType,
  UserStatus,
} from "@prisma/client";

@Injectable()
export class WorkforceRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Count active employees matching optional workplace or department filters
   */
  async countActiveEmployees(filters?: {
    workplaceId?: string;
    department?: string;
  }) {
    const where: Prisma.EmployeeProfileWhereInput = {
      user: { status: UserStatus.ACTIVE },
    };
    if (filters?.workplaceId) where.workplaceId = filters.workplaceId;
    if (filters?.department) where.department = filters.department;

    return this.prisma.employeeProfile.count({ where });
  }

  /**
   * Fetch active employees with their assigned schedule and workplace
   */
  async getActiveEmployeesWithSchedule(filters?: {
    workplaceId?: string;
    department?: string;
  }) {
    const where: Prisma.EmployeeProfileWhereInput = {
      user: { status: UserStatus.ACTIVE },
    };
    if (filters?.workplaceId) where.workplaceId = filters.workplaceId;
    if (filters?.department) where.department = filters.department;

    return this.prisma.employeeProfile.findMany({
      where,
      select: {
        id: true,
        employeeCode: true,
        firstName: true,
        lastName: true,
        jobTitle: true,
        department: true,
        workplaceId: true,
        workplace: { select: { id: true, name: true, code: true } },
        scheduleId: true,
        schedule: {
          select: {
            id: true,
            name: true,
            startTime: true,
            endTime: true,
            workingDays: true,
            graceMinutesCheckIn: true,
            graceMinutesCheckOut: true,
          },
        },
      },
    });
  }

  /**
   * Fetch attendance records for a specific date
   */
  async getAttendanceForDate(
    date: Date,
    filters?: { workplaceId?: string; department?: string },
  ) {
    const where: Prisma.AttendanceRecordWhereInput = {
      date,
    };
    if (filters?.workplaceId) where.workplaceId = filters.workplaceId;
    if (filters?.department) {
      where.employee = { department: filters.department };
    }

    return this.prisma.attendanceRecord.findMany({
      where,
      select: {
        id: true,
        employeeId: true,
        date: true,
        status: true,
        checkInTime: true,
        checkOutTime: true,
        workDurationMinutes: true,
        lateMinutes: true,
        earlyLeaveMinutes: true,
        overtimeMinutes: true,
        isSuspicious: true,
        isManualEntry: true,
        workplaceId: true,
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
        workplace: { select: { id: true, name: true, code: true } },
      },
    });
  }

  /**
   * Fetch attendance records across a date range
   */
  async getAttendanceForRange(
    startDate: Date,
    endDate: Date,
    filters?: {
      workplaceId?: string;
      department?: string;
      status?: AttendanceStatus;
    },
  ) {
    const where: Prisma.AttendanceRecordWhereInput = {
      date: { gte: startDate, lte: endDate },
    };
    if (filters?.workplaceId) where.workplaceId = filters.workplaceId;
    if (filters?.status) where.status = filters.status;
    if (filters?.department) {
      where.employee = { department: filters.department };
    }

    return this.prisma.attendanceRecord.findMany({
      where,
      select: {
        id: true,
        employeeId: true,
        date: true,
        status: true,
        checkInTime: true,
        checkOutTime: true,
        workDurationMinutes: true,
        lateMinutes: true,
        earlyLeaveMinutes: true,
        overtimeMinutes: true,
        isSuspicious: true,
        isManualEntry: true,
        workplaceId: true,
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
        workplace: { select: { id: true, name: true, code: true } },
      },
      orderBy: { date: "desc" },
    });
  }

  /**
   * Fetch approved leaves spanning the specified date
   */
  async getApprovedLeavesForDate(date: Date) {
    return this.prisma.request.findMany({
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
          ],
        },
        startDate: { lte: date },
        endDate: { gte: date },
      },
      select: {
        id: true,
        employeeId: true,
        type: true,
        startDate: true,
        endDate: true,
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            department: true,
          },
        },
      },
    });
  }

  /**
   * Group attendance records by department
   */
  async getDepartmentStats(startDate: Date, endDate: Date) {
    return this.prisma.attendanceRecord.findMany({
      where: {
        date: { gte: startDate, lte: endDate },
      },
      select: {
        status: true,
        workDurationMinutes: true,
        lateMinutes: true,
        overtimeMinutes: true,
        employee: {
          select: { department: true },
        },
      },
    });
  }

  /**
   * Group attendance records by workplace
   */
  async getWorkplaceStats(startDate: Date, endDate: Date) {
    return this.prisma.attendanceRecord.findMany({
      where: {
        date: { gte: startDate, lte: endDate },
      },
      select: {
        status: true,
        workDurationMinutes: true,
        lateMinutes: true,
        overtimeMinutes: true,
        workplace: {
          select: { id: true, name: true, code: true },
        },
      },
    });
  }

  /**
   * Top Overtime Records within a date range
   */
  async getTopOvertimeRecords(startDate: Date, endDate: Date, limit = 10) {
    return this.prisma.attendanceRecord.findMany({
      where: {
        date: { gte: startDate, lte: endDate },
        overtimeMinutes: { gt: 0 },
      },
      select: {
        id: true,
        date: true,
        overtimeMinutes: true,
        workDurationMinutes: true,
        checkInTime: true,
        checkOutTime: true,
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
        workplace: { select: { id: true, name: true } },
      },
      orderBy: { overtimeMinutes: "desc" },
      take: limit,
    });
  }

  /**
   * Batch upsert ABSENT records with audit logging
   */
  async markAbsences(
    records: Array<{
      employeeId: string;
      workplaceId?: string | null;
      date: Date;
      reason?: string;
    }>,
    actorUserId?: string,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const results = [];
      for (const rec of records) {
        const created = await tx.attendanceRecord.upsert({
          where: {
            employeeId_date: {
              employeeId: rec.employeeId,
              date: rec.date,
            },
          },
          update: {
            status: AttendanceStatus.ABSENT,
            isManualEntry: true,
            manualCorrectionReason: rec.reason || "Marked absent by system/HR",
            manualCorrectedByUserId: actorUserId,
          },
          create: {
            employeeId: rec.employeeId,
            workplaceId: rec.workplaceId || undefined,
            date: rec.date,
            status: AttendanceStatus.ABSENT,
            isManualEntry: true,
            manualCorrectionReason: rec.reason || "Marked absent by system/HR",
            manualCorrectedByUserId: actorUserId,
          },
        });

        results.push(created);
      }
      return results;
    });
  }
}
