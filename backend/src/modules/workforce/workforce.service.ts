import {
  Injectable,
  Logger,
  NotFoundException,
} from "@nestjs/common";
import { WorkforceRepository } from "./workforce.repository";
import { WorkforceQueryDto } from "./dto/workforce-query.dto";
import { MarkAbsenceDto } from "./dto/mark-absence.dto";
import { AttendanceStatus } from "@prisma/client";

@Injectable()
export class WorkforceService {
  private readonly logger = new Logger(WorkforceService.name);

  constructor(private readonly workforceRepo: WorkforceRepository) {}

  /**
   * Real-time Live Presence & Workforce Status for Today
   */
  async getLiveStatus(query: WorkforceQueryDto) {
    const targetDate = query.date ? new Date(query.date) : new Date();
    targetDate.setHours(0, 0, 0, 0);
    const dayOfWeek = targetDate.getDay();

    const [activeEmployees, attendanceRecords, approvedLeaves] =
      await Promise.all([
        this.workforceRepo.getActiveEmployeesWithSchedule({
          workplaceId: query.workplaceId,
          department: query.department,
        }),
        this.workforceRepo.getAttendanceForDate(targetDate, {
          workplaceId: query.workplaceId,
          department: query.department,
        }),
        this.workforceRepo.getApprovedLeavesForDate(targetDate),
      ]);

    const totalActiveEmployees = activeEmployees.length;
    const leaveEmployeeIds = new Set(approvedLeaves.map((l) => l.employeeId));
    const attendanceMap = new Map(attendanceRecords.map((r) => [r.employeeId, r]));

    let presentCount = 0;
    let currentlyCheckedInCount = 0;
    let checkedOutCount = 0;
    let lateCount = 0;
    let earlyLeaveCount = 0;
    let absentCount = 0;

    const presentEmployees: any[] = [];
    const notCheckedInEmployees: any[] = [];
    const onLeaveEmployees = approvedLeaves.map((l) => ({
      employeeId: l.employeeId,
      employeeCode: l.employee.employeeCode,
      name: `${l.employee.firstName} ${l.employee.lastName}`,
      department: l.employee.department,
      leaveType: l.type,
    }));

    for (const emp of activeEmployees) {
      const record = attendanceMap.get(emp.id);
      const isScheduledToday = emp.schedule?.workingDays?.includes(dayOfWeek) ?? false;
      const isOnLeave = leaveEmployeeIds.has(emp.id);

      if (record) {
        if (
          record.status === AttendanceStatus.PRESENT ||
          record.status === AttendanceStatus.LATE ||
          record.status === AttendanceStatus.EARLY_LEAVE
        ) {
          presentCount++;
          if (record.checkInTime && !record.checkOutTime) {
            currentlyCheckedInCount++;
          } else if (record.checkOutTime) {
            checkedOutCount++;
          }
          if (record.lateMinutes && record.lateMinutes > 0) {
            lateCount++;
          }
          if (record.earlyLeaveMinutes && record.earlyLeaveMinutes > 0) {
            earlyLeaveCount++;
          }

          presentEmployees.push({
            employeeId: emp.id,
            employeeCode: emp.employeeCode,
            name: `${emp.firstName} ${emp.lastName}`,
            jobTitle: emp.jobTitle,
            department: emp.department,
            workplaceName: emp.workplace?.name,
            checkInTime: record.checkInTime,
            checkOutTime: record.checkOutTime,
            status: record.status,
            lateMinutes: record.lateMinutes,
            earlyLeaveMinutes: record.earlyLeaveMinutes,
            overtimeMinutes: record.overtimeMinutes,
          });
        } else if (record.status === AttendanceStatus.ABSENT) {
          absentCount++;
        }
      } else if (isScheduledToday && !isOnLeave) {
        notCheckedInEmployees.push({
          employeeId: emp.id,
          employeeCode: emp.employeeCode,
          name: `${emp.firstName} ${emp.lastName}`,
          jobTitle: emp.jobTitle,
          department: emp.department,
          workplaceName: emp.workplace?.name,
          shiftStartTime: emp.schedule?.startTime,
          shiftEndTime: emp.schedule?.endTime,
        });
      }
    }

    const onLeaveCount = onLeaveEmployees.length;
    const notCheckedInYetCount = notCheckedInEmployees.length;
    const scheduledTotal = activeEmployees.filter(
      (e) => e.schedule?.workingDays?.includes(dayOfWeek),
    ).length;

    const presentPercentage =
      scheduledTotal > 0 ? Math.round((presentCount / scheduledTotal) * 100) : 0;

    return {
      date: targetDate.toISOString().split("T")[0],
      metrics: {
        totalActiveEmployees,
        scheduledTotal,
        presentCount,
        currentlyCheckedInCount,
        checkedOutCount,
        lateCount,
        earlyLeaveCount,
        onLeaveCount,
        absentCount,
        notCheckedInYetCount,
        presentPercentage,
      },
      presentEmployees,
      notCheckedInEmployees,
      onLeaveEmployees,
    };
  }

  /**
   * Consolidated Attendance Statistics and KPIs
   */
  async getStatistics(query: WorkforceQueryDto) {
    const { startDate, endDate } = this.resolveDateRange(query);

    const records = await this.workforceRepo.getAttendanceForRange(
      startDate,
      endDate,
      {
        workplaceId: query.workplaceId,
        department: query.department,
        status: query.status,
      },
    );

    const totalRecords = records.length;
    let presentCount = 0;
    let lateCount = 0;
    let earlyLeaveCount = 0;
    let absentCount = 0;
    let onLeaveCount = 0;
    let totalWorkDurationMinutes = 0;
    let totalLateMinutes = 0;
    let totalEarlyLeaveMinutes = 0;
    let totalOvertimeMinutes = 0;

    for (const r of records) {
      if (
        r.status === AttendanceStatus.PRESENT ||
        r.status === AttendanceStatus.LATE ||
        r.status === AttendanceStatus.EARLY_LEAVE
      ) {
        presentCount++;
      }
      if (r.status === AttendanceStatus.LATE || (r.lateMinutes && r.lateMinutes > 0)) {
        lateCount++;
      }
      if (
        r.status === AttendanceStatus.EARLY_LEAVE ||
        (r.earlyLeaveMinutes && r.earlyLeaveMinutes > 0)
      ) {
        earlyLeaveCount++;
      }
      if (r.status === AttendanceStatus.ABSENT) {
        absentCount++;
      }
      if (r.status === AttendanceStatus.ON_LEAVE) {
        onLeaveCount++;
      }

      totalWorkDurationMinutes += r.workDurationMinutes || 0;
      totalLateMinutes += r.lateMinutes || 0;
      totalEarlyLeaveMinutes += r.earlyLeaveMinutes || 0;
      totalOvertimeMinutes += r.overtimeMinutes || 0;
    }

    const attendanceRatePercentage =
      totalRecords > 0 ? Math.round((presentCount / totalRecords) * 100) : 0;
    const punctualityRatePercentage =
      presentCount > 0
        ? Math.round(((presentCount - lateCount) / presentCount) * 100)
        : 0;

    return {
      period: {
        startDate: startDate.toISOString().split("T")[0],
        endDate: endDate.toISOString().split("T")[0],
      },
      summary: {
        totalRecords,
        presentCount,
        lateCount,
        earlyLeaveCount,
        absentCount,
        onLeaveCount,
        attendanceRatePercentage,
        punctualityRatePercentage,
        totalWorkHours: Math.round((totalWorkDurationMinutes / 60) * 10) / 10,
        totalWorkDurationMinutes,
        totalLateMinutes,
        totalEarlyLeaveMinutes,
        totalOvertimeHours: Math.round((totalOvertimeMinutes / 60) * 10) / 10,
        totalOvertimeMinutes,
      },
    };
  }

  /**
   * Daily / Periodic Attendance Trend Summary
   */
  async getSummary(query: WorkforceQueryDto) {
    const { startDate, endDate } = this.resolveDateRange(query);
    const records = await this.workforceRepo.getAttendanceForRange(
      startDate,
      endDate,
      {
        workplaceId: query.workplaceId,
        department: query.department,
        status: query.status,
      },
    );

    // Aggregate by date (YYYY-MM-DD)
    const dailyMap = new Map<string, any>();

    for (const r of records) {
      const dateKey = r.date.toISOString().split("T")[0];
      if (!dailyMap.has(dateKey)) {
        dailyMap.set(dateKey, {
          date: dateKey,
          total: 0,
          present: 0,
          late: 0,
          earlyLeave: 0,
          absent: 0,
          onLeave: 0,
          workDurationMinutes: 0,
          overtimeMinutes: 0,
        });
      }

      const entry = dailyMap.get(dateKey);
      entry.total++;
      if (
        r.status === AttendanceStatus.PRESENT ||
        r.status === AttendanceStatus.LATE ||
        r.status === AttendanceStatus.EARLY_LEAVE
      ) {
        entry.present++;
      }
      if (r.status === AttendanceStatus.LATE || (r.lateMinutes && r.lateMinutes > 0)) {
        entry.late++;
      }
      if (
        r.status === AttendanceStatus.EARLY_LEAVE ||
        (r.earlyLeaveMinutes && r.earlyLeaveMinutes > 0)
      ) {
        entry.earlyLeave++;
      }
      if (r.status === AttendanceStatus.ABSENT) {
        entry.absent++;
      }
      if (r.status === AttendanceStatus.ON_LEAVE) {
        entry.onLeave++;
      }
      entry.workDurationMinutes += r.workDurationMinutes || 0;
      entry.overtimeMinutes += r.overtimeMinutes || 0;
    }

    const dailySummary = Array.from(dailyMap.values()).sort(
      (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
    );

    const page = query.page || 1;
    const limit = query.limit || 30;
    const paginated = dailySummary.slice((page - 1) * limit, page * limit);

    return {
      period: {
        startDate: startDate.toISOString().split("T")[0],
        endDate: endDate.toISOString().split("T")[0],
      },
      data: paginated,
      meta: {
        page,
        limit,
        total: dailySummary.length,
        totalPages: Math.ceil(dailySummary.length / limit),
      },
    };
  }

  /**
   * Department-Level Workforce Distribution & Performance
   */
  async getDepartmentWorkforce(query: WorkforceQueryDto) {
    const { startDate, endDate } = this.resolveDateRange(query);
    const records = await this.workforceRepo.getDepartmentStats(
      startDate,
      endDate,
    );

    const deptMap = new Map<string, any>();

    for (const r of records) {
      const dept = r.employee?.department || "General";
      if (!deptMap.has(dept)) {
        deptMap.set(dept, {
          department: dept,
          totalRecords: 0,
          presentCount: 0,
          lateCount: 0,
          absentCount: 0,
          totalWorkHours: 0,
          totalOvertimeHours: 0,
        });
      }

      const d = deptMap.get(dept);
      d.totalRecords++;
      if (
        r.status === AttendanceStatus.PRESENT ||
        r.status === AttendanceStatus.LATE ||
        r.status === AttendanceStatus.EARLY_LEAVE
      ) {
        d.presentCount++;
      }
      if (r.status === AttendanceStatus.LATE || (r.lateMinutes && r.lateMinutes > 0)) {
        d.lateCount++;
      }
      if (r.status === AttendanceStatus.ABSENT) {
        d.absentCount++;
      }
      d.totalWorkHours += Math.round(((r.workDurationMinutes || 0) / 60) * 10) / 10;
      d.totalOvertimeHours +=
        Math.round(((r.overtimeMinutes || 0) / 60) * 10) / 10;
    }

    return {
      period: {
        startDate: startDate.toISOString().split("T")[0],
        endDate: endDate.toISOString().split("T")[0],
      },
      departments: Array.from(deptMap.values()),
    };
  }

  /**
   * Workplace/Branch-Level Workforce Distribution & Performance
   */
  async getWorkplaceWorkforce(query: WorkforceQueryDto) {
    const { startDate, endDate } = this.resolveDateRange(query);
    const records = await this.workforceRepo.getWorkplaceStats(
      startDate,
      endDate,
    );

    const wpMap = new Map<string, any>();

    for (const r of records) {
      const wpId = r.workplace?.id || "unassigned";
      const wpName = r.workplace?.name || "Unassigned Workplace";
      const wpCode = r.workplace?.code || "N/A";

      if (!wpMap.has(wpId)) {
        wpMap.set(wpId, {
          workplaceId: wpId,
          workplaceName: wpName,
          workplaceCode: wpCode,
          totalRecords: 0,
          presentCount: 0,
          lateCount: 0,
          absentCount: 0,
          totalWorkHours: 0,
          totalOvertimeHours: 0,
        });
      }

      const wp = wpMap.get(wpId);
      wp.totalRecords++;
      if (
        r.status === AttendanceStatus.PRESENT ||
        r.status === AttendanceStatus.LATE ||
        r.status === AttendanceStatus.EARLY_LEAVE
      ) {
        wp.presentCount++;
      }
      if (r.status === AttendanceStatus.LATE || (r.lateMinutes && r.lateMinutes > 0)) {
        wp.lateCount++;
      }
      if (r.status === AttendanceStatus.ABSENT) {
        wp.absentCount++;
      }
      wp.totalWorkHours +=
        Math.round(((r.workDurationMinutes || 0) / 60) * 10) / 10;
      wp.totalOvertimeHours +=
        Math.round(((r.overtimeMinutes || 0) / 60) * 10) / 10;
    }

    return {
      period: {
        startDate: startDate.toISOString().split("T")[0],
        endDate: endDate.toISOString().split("T")[0],
      },
      workplaces: Array.from(wpMap.values()),
    };
  }

  /**
   * Query Absent Employees on a given date (scheduled with no check-in and no approved leave)
   */
  async getAbsentEmployees(
    dateStr?: string,
    workplaceId?: string,
    department?: string,
  ) {
    const targetDate = dateStr ? new Date(dateStr) : new Date();
    targetDate.setHours(0, 0, 0, 0);
    const dayOfWeek = targetDate.getDay();

    const [employees, attendanceRecords, leaves] = await Promise.all([
      this.workforceRepo.getActiveEmployeesWithSchedule({
        workplaceId,
        department,
      }),
      this.workforceRepo.getAttendanceForDate(targetDate, {
        workplaceId,
        department,
      }),
      this.workforceRepo.getApprovedLeavesForDate(targetDate),
    ]);

    const attendanceMap = new Map(attendanceRecords.map((r) => [r.employeeId, r]));
    const leaveEmployeeIds = new Set(leaves.map((l) => l.employeeId));

    const absentEmployees = [];

    for (const emp of employees) {
      const isScheduled = emp.schedule?.workingDays?.includes(dayOfWeek);
      const hasAttendance = attendanceMap.has(emp.id);
      const isOnLeave = leaveEmployeeIds.has(emp.id);

      if (isScheduled && !hasAttendance && !isOnLeave) {
        absentEmployees.push({
          employeeId: emp.id,
          employeeCode: emp.employeeCode,
          firstName: emp.firstName,
          lastName: emp.lastName,
          department: emp.department,
          jobTitle: emp.jobTitle,
          workplaceId: emp.workplaceId,
          workplaceName: emp.workplace?.name,
          shift: emp.schedule
            ? `${emp.schedule.startTime} - ${emp.schedule.endTime}`
            : "Default",
        });
      }
    }

    return {
      date: targetDate.toISOString().split("T")[0],
      absentCount: absentEmployees.length,
      employees: absentEmployees,
    };
  }

  /**
   * Batch mark absences for specified or auto-detected employees
   */
  async markAbsences(actorUserId: string, dto: MarkAbsenceDto) {
    const targetDate = new Date(dto.date);
    targetDate.setHours(0, 0, 0, 0);

    let candidatesToMark: Array<{ employeeId: string; workplaceId?: string | null }> = [];

    if (dto.employeeIds && dto.employeeIds.length > 0) {
      candidatesToMark = dto.employeeIds.map((id) => ({ employeeId: id }));
    } else {
      const detected = await this.getAbsentEmployees(dto.date);
      candidatesToMark = detected.employees.map((e) => ({
        employeeId: e.employeeId,
        workplaceId: e.workplaceId,
      }));
    }

    if (candidatesToMark.length === 0) {
      return {
        message: "No unexcused absences found to mark for this date",
        count: 0,
        records: [],
      };
    }

    const records = await this.workforceRepo.markAbsences(
      candidatesToMark.map((c) => ({
        employeeId: c.employeeId,
        workplaceId: c.workplaceId,
        date: targetDate,
        reason: dto.reason || "Auto-detected unexcused absence",
      })),
      actorUserId,
    );

    return {
      message: `Successfully marked ${records.length} absences for ${dto.date}`,
      count: records.length,
      records,
    };
  }

  /**
   * Overtime Ranking & Summaries
   */
  async getOvertimeSummary(query: WorkforceQueryDto) {
    const { startDate, endDate } = this.resolveDateRange(query);
    const limit = query.limit || 10;

    const topRecords = await this.workforceRepo.getTopOvertimeRecords(
      startDate,
      endDate,
      limit,
    );

    let totalOvertimeMinutes = 0;
    const employeeOvertimeMap = new Map<string, any>();

    for (const r of topRecords) {
      totalOvertimeMinutes += r.overtimeMinutes || 0;
      const empId = r.employee.id;

      if (!employeeOvertimeMap.has(empId)) {
        employeeOvertimeMap.set(empId, {
          employeeId: empId,
          employeeCode: r.employee.employeeCode,
          name: `${r.employee.firstName} ${r.employee.lastName}`,
          department: r.employee.department,
          jobTitle: r.employee.jobTitle,
          totalOvertimeMinutes: 0,
          totalOvertimeHours: 0,
          sessionCount: 0,
        });
      }

      const emp = employeeOvertimeMap.get(empId);
      emp.totalOvertimeMinutes += r.overtimeMinutes || 0;
      emp.sessionCount++;
      emp.totalOvertimeHours =
        Math.round((emp.totalOvertimeMinutes / 60) * 10) / 10;
    }

    return {
      period: {
        startDate: startDate.toISOString().split("T")[0],
        endDate: endDate.toISOString().split("T")[0],
      },
      totalOvertimeHours:
        Math.round((totalOvertimeMinutes / 60) * 10) / 10,
      topEmployees: Array.from(employeeOvertimeMap.values()).sort(
        (a, b) => b.totalOvertimeMinutes - a.totalOvertimeMinutes,
      ),
      records: topRecords,
    };
  }

  /**
   * Helper to normalize startDate/endDate from Query DTO (supports month or date ranges)
   */
  private resolveDateRange(query: WorkforceQueryDto) {
    let startDate: Date;
    let endDate: Date;

    if (query.month) {
      const [year, month] = query.month.split("-").map(Number);
      startDate = new Date(year, month - 1, 1);
      endDate = new Date(year, month, 0, 23, 59, 59);
    } else if (query.startDate && query.endDate) {
      startDate = new Date(query.startDate);
      startDate.setHours(0, 0, 0, 0);
      endDate = new Date(query.endDate);
      endDate.setHours(23, 59, 59, 999);
    } else if (query.date) {
      startDate = new Date(query.date);
      startDate.setHours(0, 0, 0, 0);
      endDate = new Date(query.date);
      endDate.setHours(23, 59, 59, 999);
    } else {
      // Default: current month
      const now = new Date();
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
    }

    return { startDate, endDate };
  }
}
