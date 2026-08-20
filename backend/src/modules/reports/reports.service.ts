import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { AttendanceStatus, RequestStatus, UserStatus } from "@prisma/client";

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  async getDashboardSummary() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      totalEmployees,
      activeEmployees,
      todayAttendances,
      pendingRequests,
      pendingAdvances,
      workplacesCount,
    ] = await Promise.all([
      this.prisma.employeeProfile.count(),
      this.prisma.user.count({ where: { status: UserStatus.ACTIVE } }),
      this.prisma.attendanceRecord.findMany({
        where: { date: today },
        select: { status: true },
      }),
      this.prisma.request.count({ where: { status: RequestStatus.PENDING } }),
      this.prisma.financialAdvance.count({ where: { status: "PENDING" } }),
      this.prisma.workplace.count({ where: { isActive: true } }),
    ]);

    const presentCount = todayAttendances.filter(
      (a) => a.status === AttendanceStatus.PRESENT,
    ).length;
    const lateCount = todayAttendances.filter(
      (a) => a.status === AttendanceStatus.LATE,
    ).length;
    const absentCount = Math.max(
      0,
      totalEmployees - (presentCount + lateCount),
    );

    return {
      employees: {
        total: totalEmployees,
        active: activeEmployees,
      },
      todayAttendance: {
        totalCheckedIn: todayAttendances.length,
        present: presentCount,
        late: lateCount,
        absent: absentCount,
      },
      pendingActions: {
        requests: pendingRequests,
        advances: pendingAdvances,
      },
      workplacesCount,
    };
  }

  async getDepartmentStats() {
    const employees = await this.prisma.employeeProfile.groupBy({
      by: ["department"],
      _count: { id: true },
    });

    return employees.map((e) => ({
      department: e.department,
      employeeCount: e._count.id,
    }));
  }
}
