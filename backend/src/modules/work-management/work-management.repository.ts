import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { Prisma, TaskReportStatus, TaskStatus } from "@prisma/client";
import { SubmitTaskReportDto, TaskReviewAction } from "./dto";

@Injectable()
export class WorkManagementRepository {
  constructor(private readonly prisma: PrismaService) {}

  async submitReport(
    taskId: string,
    employeeId: string,
    userId: string,
    dto: SubmitTaskReportDto,
  ) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Create TaskReport record
      const report = await tx.taskReport.create({
        data: {
          taskId,
          employeeId,
          summary: dto.summary,
          challenges: dto.challenges,
          hoursSpent: dto.hoursSpent,
          progress: dto.progress ?? 100,
          attachments: dto.attachments ? dto.attachments : undefined,
          status: TaskReportStatus.SUBMITTED,
        },
      });

      // 2. Update Task Status to PENDING_REVIEW and progress
      const updatedTask = await tx.task.update({
        where: { id: taskId },
        data: {
          status: TaskStatus.PENDING_REVIEW,
          progress: dto.progress ?? 100,
        },
        include: {
          assignee: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              userId: true,
              managerId: true,
              manager: { select: { userId: true } },
            },
          },
          creator: { select: { id: true, email: true } },
        },
      });

      // 3. Record TaskHistory
      await tx.taskHistory.create({
        data: {
          taskId,
          userId,
          action: "TASK_REPORT_SUBMITTED",
          oldStatus: TaskStatus.IN_PROGRESS,
          newStatus: TaskStatus.PENDING_REVIEW,
          comment: `Report submitted: ${dto.summary.slice(0, 100)}`,
          metadata: { reportId: report.id, hoursSpent: dto.hoursSpent },
        },
      });

      return { report, task: updatedTask };
    });
  }

  async findLatestReportByTaskId(taskId: string) {
    return this.prisma.taskReport.findFirst({
      where: { taskId },
      orderBy: { createdAt: "desc" },
    });
  }

  async reviewReport(
    taskId: string,
    reportId: string,
    reviewerUserId: string,
    action: TaskReviewAction,
    reviewNotes?: string,
    rating?: number,
  ) {
    const isApproved = action === TaskReviewAction.APPROVE;
    const newStatus = isApproved
      ? TaskStatus.COMPLETED
      : TaskStatus.IN_PROGRESS;
    const reportStatus = isApproved
      ? TaskReportStatus.APPROVED
      : TaskReportStatus.REJECTED;

    return this.prisma.$transaction(async (tx) => {
      // 1. Update TaskReport
      const updatedReport = await tx.taskReport.update({
        where: { id: reportId },
        data: {
          status: reportStatus,
          reviewedById: reviewerUserId,
          reviewedAt: new Date(),
          reviewNotes,
          rating,
        },
      });

      // 2. Update Task
      const taskUpdateData: Prisma.TaskUpdateInput = {
        status: newStatus,
        ...(isApproved ? { completedAt: new Date(), progress: 100 } : {}),
      };

      const updatedTask = await tx.task.update({
        where: { id: taskId },
        data: taskUpdateData,
        include: {
          assignee: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              userId: true,
            },
          },
        },
      });

      // 3. Record TaskHistory
      await tx.taskHistory.create({
        data: {
          taskId,
          userId: reviewerUserId,
          action: isApproved ? "TASK_REPORT_APPROVED" : "TASK_REPORT_REJECTED",
          oldStatus: TaskStatus.PENDING_REVIEW,
          newStatus,
          comment:
            reviewNotes ||
            (isApproved ? "Approved by manager" : "Rejected by manager"),
          metadata: { reportId, rating },
        },
      });

      return { report: updatedReport, task: updatedTask };
    });
  }

  async findPendingReviews(params: {
    managerEmployeeId?: string;
    departmentId?: string;
    isSuperAdmin?: boolean;
    limit?: number;
    page?: number;
  }) {
    const {
      managerEmployeeId,
      departmentId,
      isSuperAdmin,
      limit = 10,
      page = 1,
    } = params;
    const skip = (page - 1) * limit;

    const where: Prisma.TaskWhereInput = {
      status: TaskStatus.PENDING_REVIEW,
    };

    if (!isSuperAdmin) {
      where.OR = [
        ...(managerEmployeeId
          ? [{ assignee: { managerId: managerEmployeeId } }]
          : []),
        ...(departmentId ? [{ departmentId }] : []),
      ];
    }

    const [total, tasks] = await Promise.all([
      this.prisma.task.count({ where }),
      this.prisma.task.findMany({
        where,
        skip,
        take: limit,
        orderBy: { updatedAt: "desc" },
        include: {
          assignee: {
            select: {
              id: true,
              employeeCode: true,
              firstName: true,
              lastName: true,
              jobTitle: true,
              department: true,
              userId: true,
            },
          },
          reports: {
            where: { status: TaskReportStatus.SUBMITTED },
            orderBy: { createdAt: "desc" },
            take: 1,
          },
          department: {
            select: {
              id: true,
              name: true,
              code: true,
            },
          },
        },
      }),
    ]);

    return {
      data: tasks,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getDepartmentWorkload(departmentId?: string) {
    const where: Prisma.EmployeeProfileWhereInput = departmentId
      ? { departmentId }
      : {};

    const employees = await this.prisma.employeeProfile.findMany({
      where,
      select: {
        id: true,
        employeeCode: true,
        firstName: true,
        lastName: true,
        jobTitle: true,
        department: true,
        departmentId: true,
        assignedTasks: {
          select: {
            id: true,
            status: true,
            priority: true,
            dueDate: true,
          },
        },
      },
      take: 100, // Safe page limit for low memory load
    });

    const now = new Date();

    return employees.map((emp) => {
      const tasks = emp.assignedTasks;
      const total = tasks.length;
      const active = tasks.filter(
        (t) =>
          t.status === TaskStatus.TODO ||
          t.status === TaskStatus.ACCEPTED ||
          t.status === TaskStatus.IN_PROGRESS ||
          t.status === TaskStatus.BLOCKED ||
          t.status === TaskStatus.PENDING_REVIEW,
      ).length;

      const completed = tasks.filter(
        (t) => t.status === TaskStatus.COMPLETED,
      ).length;

      const overdue = tasks.filter(
        (t) =>
          t.dueDate &&
          new Date(t.dueDate) < now &&
          t.status !== TaskStatus.COMPLETED &&
          t.status !== TaskStatus.CANCELLED,
      ).length;

      return {
        employeeId: emp.id,
        employeeCode: emp.employeeCode,
        fullName: `${emp.firstName} ${emp.lastName}`,
        jobTitle: emp.jobTitle,
        department: emp.department,
        totalTasks: total,
        activeTasks: active,
        completedTasks: completed,
        overdueTasks: overdue,
        completionRate: total > 0 ? Math.round((completed / total) * 100) : 0,
      };
    });
  }

  async markOverdueTasks() {
    const now = new Date();
    return this.prisma.task.updateMany({
      where: {
        dueDate: { lt: now },
        status: {
          in: [
            TaskStatus.TODO,
            TaskStatus.ACCEPTED,
            TaskStatus.IN_PROGRESS,
            TaskStatus.BLOCKED,
          ],
        },
      },
      data: {
        status: TaskStatus.OVERDUE,
      },
    });
  }
}
