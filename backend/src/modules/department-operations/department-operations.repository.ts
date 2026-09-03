import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  AttendanceStatus,
  HandoverStatus,
  ServiceRequestPriority,
  ServiceRequestStatus,
  TaskStatus,
} from "@prisma/client";

@Injectable()
export class DepartmentOperationsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async getDepartmentOverview(
    departmentId: string,
    dateStr?: string,
    workplaceId?: string,
  ) {
    const targetDate = dateStr ? new Date(dateStr) : new Date();
    targetDate.setHours(0, 0, 0, 0);

    const [
      department,
      totalEmployees,
      presentEmployeesCount,
      taskStats,
      serviceRequestStats,
      urgentServiceRequestsCount,
      todayHandover,
    ] = await Promise.all([
      // 1. Department details
      this.prisma.department.findUnique({
        where: { id: departmentId },
        select: {
          id: true,
          name: true,
          code: true,
          headOfDepartment: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              jobTitle: true,
            },
          },
        },
      }),

      // 2. Total active employees in department
      this.prisma.employeeProfile.count({
        where: {
          departmentId,
          user: { status: "ACTIVE" },
        },
      }),

      // 3. Present staff today on shift
      this.prisma.attendanceRecord.count({
        where: {
          date: targetDate,
          status: AttendanceStatus.PRESENT,
          employee: {
            departmentId,
          },
        },
      }),

      // 4. Tasks status grouping
      this.prisma.task.groupBy({
        by: ["status"],
        where: {
          departmentId,
          ...(workplaceId ? { workplaceId } : {}),
        },
        _count: {
          id: true,
        },
      }),

      // 5. Service requests status grouping
      this.prisma.serviceRequest.groupBy({
        by: ["status"],
        where: {
          departmentId,
        },
        _count: {
          id: true,
        },
      }),

      // 6. Urgent / Critical service requests pending
      this.prisma.serviceRequest.count({
        where: {
          departmentId,
          priority: {
            in: [ServiceRequestPriority.HIGH, ServiceRequestPriority.URGENT],
          },
          status: {
            in: [
              ServiceRequestStatus.SUBMITTED,
              ServiceRequestStatus.ASSIGNED,
              ServiceRequestStatus.IN_PROGRESS,
            ],
          },
        },
      }),

      // 7. Latest handover for today
      this.prisma.shiftHandover.findFirst({
        where: {
          departmentId,
          shiftDate: targetDate,
        },
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          handoverNumber: true,
          shiftName: true,
          status: true,
          acknowledgedAt: true,
          handedOverBy: {
            select: { firstName: true, lastName: true },
          },
          receivedBy: {
            select: { firstName: true, lastName: true },
          },
        },
      }),
    ]);

    // Format tasks counts
    const taskBreakdown: Record<string, number> = {
      TODO: 0,
      ACCEPTED: 0,
      IN_PROGRESS: 0,
      BLOCKED: 0,
      PENDING_REVIEW: 0,
      COMPLETED: 0,
      OVERDUE: 0,
    };
    for (const stat of taskStats) {
      taskBreakdown[stat.status] = stat._count.id;
    }

    // Format service requests counts
    const serviceRequestBreakdown: Record<string, number> = {
      SUBMITTED: 0,
      ASSIGNED: 0,
      IN_PROGRESS: 0,
      COMPLETED: 0,
      UNDER_REVIEW: 0,
      CLOSED: 0,
      CANCELLED: 0,
      REJECTED: 0,
    };
    for (const stat of serviceRequestStats) {
      serviceRequestBreakdown[stat.status] = stat._count.id;
    }

    const activeTasksCount =
      taskBreakdown.TODO +
      taskBreakdown.ACCEPTED +
      taskBreakdown.IN_PROGRESS +
      taskBreakdown.BLOCKED +
      taskBreakdown.OVERDUE;

    const activeServiceRequestsCount =
      serviceRequestBreakdown.SUBMITTED +
      serviceRequestBreakdown.ASSIGNED +
      serviceRequestBreakdown.IN_PROGRESS;

    return {
      department,
      staffing: {
        totalEmployees,
        onDutyPresent: presentEmployeesCount,
      },
      tasks: {
        activeCount: activeTasksCount,
        breakdown: taskBreakdown,
      },
      serviceRequests: {
        activeCount: activeServiceRequestsCount,
        urgentCount: urgentServiceRequestsCount,
        breakdown: serviceRequestBreakdown,
      },
      handover: todayHandover || null,
      date: targetDate.toISOString().split("T")[0],
    };
  }

  async getDepartmentKPIs(
    departmentId: string,
    startDate: Date,
    endDate: Date,
  ) {
    const [
      totalTasks,
      completedTasks,
      totalServiceRequests,
      completedServiceRequests,
      resolvedRequestsWithTimes,
      totalHandovers,
      acknowledgedHandovers,
      employeeWorkload,
    ] = await Promise.all([
      // Total tasks in date range
      this.prisma.task.count({
        where: {
          departmentId,
          createdAt: { gte: startDate, lte: endDate },
        },
      }),

      // Completed tasks
      this.prisma.task.count({
        where: {
          departmentId,
          status: TaskStatus.COMPLETED,
          createdAt: { gte: startDate, lte: endDate },
        },
      }),

      // Total service requests
      this.prisma.serviceRequest.count({
        where: {
          departmentId,
          createdAt: { gte: startDate, lte: endDate },
        },
      }),

      // Completed or closed service requests
      this.prisma.serviceRequest.count({
        where: {
          departmentId,
          status: {
            in: [ServiceRequestStatus.COMPLETED, ServiceRequestStatus.CLOSED],
          },
          createdAt: { gte: startDate, lte: endDate },
        },
      }),

      // Service requests with timestamps for SLA calculation
      this.prisma.serviceRequest.findMany({
        where: {
          departmentId,
          completedAt: { not: null },
          createdAt: { gte: startDate, lte: endDate },
        },
        select: {
          createdAt: true,
          completedAt: true,
        },
      }),

      // Handovers
      this.prisma.shiftHandover.count({
        where: {
          departmentId,
          shiftDate: { gte: startDate, lte: endDate },
        },
      }),

      // Acknowledged handovers
      this.prisma.shiftHandover.count({
        where: {
          departmentId,
          status: HandoverStatus.ACKNOWLEDGED,
          shiftDate: { gte: startDate, lte: endDate },
        },
      }),

      // Employee workload distribution
      this.prisma.employeeProfile.findMany({
        where: {
          departmentId,
          user: { status: "ACTIVE" },
        },
        select: {
          id: true,
          firstName: true,
          lastName: true,
          jobTitle: true,
          assignedTasks: {
            where: {
              status: {
                in: [
                  TaskStatus.TODO,
                  TaskStatus.ACCEPTED,
                  TaskStatus.IN_PROGRESS,
                  TaskStatus.BLOCKED,
                ],
              },
            },
            select: { id: true },
          },
          serviceRequestsAssigned: {
            where: {
              status: {
                in: [
                  ServiceRequestStatus.ASSIGNED,
                  ServiceRequestStatus.IN_PROGRESS,
                ],
              },
            },
            select: { id: true },
          },
        },
      }),
    ]);

    // Average resolution time in hours
    let avgResolutionHours = 0;
    if (resolvedRequestsWithTimes.length > 0) {
      const totalHours = resolvedRequestsWithTimes.reduce((acc, req) => {
        if (!req.completedAt) return acc;
        const diffMs = req.completedAt.getTime() - req.createdAt.getTime();
        return acc + diffMs / (1000 * 60 * 60);
      }, 0);
      avgResolutionHours = Number(
        (totalHours / resolvedRequestsWithTimes.length).toFixed(1),
      );
    }

    const taskCompletionRate =
      totalTasks > 0
        ? Number(((completedTasks / totalTasks) * 100).toFixed(1))
        : 100;

    const requestResolutionRate =
      totalServiceRequests > 0
        ? Number(
            ((completedServiceRequests / totalServiceRequests) * 100).toFixed(
              1,
            ),
          )
        : 100;

    const handoverComplianceRate =
      totalHandovers > 0
        ? Number(((acknowledgedHandovers / totalHandovers) * 100).toFixed(1))
        : 100;

    const workloadDistribution = employeeWorkload.map((emp) => ({
      employeeId: emp.id,
      name: `${emp.firstName} ${emp.lastName}`,
      jobTitle: emp.jobTitle,
      activeTasksCount: emp.assignedTasks.length,
      activeServiceRequestsCount: emp.serviceRequestsAssigned.length,
      totalActiveItems:
        emp.assignedTasks.length + emp.serviceRequestsAssigned.length,
    }));

    return {
      period: {
        startDate: startDate.toISOString().split("T")[0],
        endDate: endDate.toISOString().split("T")[0],
      },
      tasks: {
        total: totalTasks,
        completed: completedTasks,
        completionRate: taskCompletionRate,
      },
      serviceRequests: {
        total: totalServiceRequests,
        completed: completedServiceRequests,
        resolutionRate: requestResolutionRate,
        averageResolutionHours: avgResolutionHours,
      },
      handovers: {
        total: totalHandovers,
        acknowledged: acknowledgedHandovers,
        complianceRate: handoverComplianceRate,
      },
      workloadDistribution,
    };
  }
}
