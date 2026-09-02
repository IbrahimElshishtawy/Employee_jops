import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from "@nestjs/common";
import { WorkManagementRepository } from "./work-management.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  SubmitTaskReportDto,
  ReviewTaskReportDto,
  TaskReviewAction,
  QueryWorkloadDto,
} from "./dto";
import {
  AuditAction,
  NotificationType,
  Role,
  TaskReportStatus,
  TaskStatus,
} from "@prisma/client";

@Injectable()
export class WorkManagementService {
  private readonly logger = new Logger(WorkManagementService.name);

  constructor(
    private readonly workRepo: WorkManagementRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ============================================================
  // 1. SUBMIT EMPLOYEE TASK REPORT
  // ============================================================

  async submitTaskReport(
    taskId: string,
    userId: string,
    dto: SubmitTaskReportDto,
  ) {
    const task = await this.prisma.task.findUnique({
      where: { id: taskId },
      include: {
        assignee: {
          select: {
            id: true,
            userId: true,
            firstName: true,
            lastName: true,
            managerId: true,
            manager: { select: { userId: true } },
          },
        },
      },
    });

    if (!task) {
      throw new NotFoundException(`Task ${taskId} not found`);
    }

    if (!task.assignee) {
      throw new BadRequestException(
        "Cannot submit a report for an unassigned task",
      );
    }

    // Only assigned employee (or SUPER_ADMIN) can submit a report
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (task.assignee.userId !== userId && user?.role !== Role.SUPER_ADMIN) {
      throw new ForbiddenException(
        "Only the assigned employee can submit a report for this task",
      );
    }

    // Task must be in executable or overdue state
    const validStatuses: TaskStatus[] = [
      TaskStatus.IN_PROGRESS,
      TaskStatus.ACCEPTED,
      TaskStatus.BLOCKED,
      TaskStatus.OVERDUE,
      TaskStatus.TODO,
    ];

    if (!validStatuses.includes(task.status)) {
      throw new BadRequestException(
        `Cannot submit task report when task is in ${task.status} status`,
      );
    }

    const { report, task: updatedTask } = await this.workRepo.submitReport(
      taskId,
      task.assignee.id,
      userId,
      dto,
    );

    // Audit Log
    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.TASK_REPORT_SUBMITTED,
        entity: "TaskReport",
        entityId: report.id,
        payload: {
          taskId,
          summary: dto.summary,
          hoursSpent: dto.hoursSpent,
          progress: dto.progress ?? 100,
        },
      },
    });

    // Notify Manager or Task Creator
    const managerUserId = task.assignee.manager?.userId || task.creatorId;

    if (managerUserId && managerUserId !== userId) {
      await this.notificationsService.sendNotification(
        managerUserId,
        "Task Report Submitted",
        `${task.assignee.firstName} ${task.assignee.lastName} submitted a report for task "${task.title}"`,
        NotificationType.TASK_REPORT_SUBMITTED,
        { taskId, reportId: report.id },
      );
    }

    return { report, task: updatedTask };
  }

  // ============================================================
  // 2. MANAGER REVIEW & APPROVAL / REJECTION
  // ============================================================

  async reviewTaskReport(
    taskId: string,
    reviewerUserId: string,
    dto: ReviewTaskReportDto,
  ) {
    const task = await this.prisma.task.findUnique({
      where: { id: taskId },
      include: {
        assignee: {
          select: {
            id: true,
            userId: true,
            firstName: true,
            lastName: true,
            managerId: true,
            manager: { select: { userId: true } },
            departmentRel: {
              select: {
                headOfDepartmentId: true,
                headOfDepartment: { select: { userId: true } },
              },
            },
          },
        },
      },
    });

    if (!task) {
      throw new NotFoundException(`Task ${taskId} not found`);
    }

    if (task.status !== TaskStatus.PENDING_REVIEW) {
      throw new BadRequestException(
        `Cannot review task in status ${task.status}. Task must be in PENDING_REVIEW status.`,
      );
    }

    // Prevention of self-approval
    if (task.assignee && task.assignee.userId === reviewerUserId) {
      throw new ForbiddenException(
        "Self-review is strictly forbidden: you cannot approve your own task report",
      );
    }

    // Authorization verification
    const reviewerUser = await this.prisma.user.findUnique({
      where: { id: reviewerUserId },
      include: { employeeProfile: true },
    });

    if (!reviewerUser) {
      throw new NotFoundException("Reviewer user not found");
    }

    const isSuperAdminOrHrAdmin =
      reviewerUser.role === Role.SUPER_ADMIN ||
      reviewerUser.role === Role.HR_ADMIN;

    const isDirectManager = task.assignee?.manager?.userId === reviewerUserId;

    const isDepartmentHead =
      task.assignee?.departmentRel?.headOfDepartment?.userId === reviewerUserId;

    const isTaskCreator = task.creatorId === reviewerUserId;

    if (
      !isSuperAdminOrHrAdmin &&
      !isDirectManager &&
      !isDepartmentHead &&
      !isTaskCreator
    ) {
      throw new ForbiddenException(
        "You are not authorized to review this employee's task report",
      );
    }

    if (
      dto.action === TaskReviewAction.REJECT &&
      (!dto.reviewNotes || dto.reviewNotes.trim().length === 0)
    ) {
      throw new BadRequestException(
        "Review notes / feedback are required when returning a task report for revision",
      );
    }

    const latestReport = await this.workRepo.findLatestReportByTaskId(taskId);
    if (!latestReport || latestReport.status !== TaskReportStatus.SUBMITTED) {
      throw new BadRequestException("No pending task report found for review");
    }

    const { report, task: updatedTask } = await this.workRepo.reviewReport(
      taskId,
      latestReport.id,
      reviewerUserId,
      dto.action,
      dto.reviewNotes,
      dto.rating,
    );

    // Audit Log
    await this.prisma.auditLog.create({
      data: {
        userId: reviewerUserId,
        action: AuditAction.TASK_REPORT_REVIEWED,
        entity: "TaskReport",
        entityId: report.id,
        payload: {
          taskId,
          action: dto.action,
          reviewNotes: dto.reviewNotes,
          rating: dto.rating,
        },
      },
    });

    // Notify Employee
    if (task.assignee?.userId) {
      const isApproved = dto.action === TaskReviewAction.APPROVE;
      const title = isApproved
        ? "Task Report Approved"
        : "Task Report Returned for Revision";
      const body = isApproved
        ? `Your report for task "${task.title}" was approved! Task completed.`
        : `Your report for task "${task.title}" was returned: ${dto.reviewNotes}`;

      await this.notificationsService.sendNotification(
        task.assignee.userId,
        title,
        body,
        NotificationType.TASK_REPORT_REVIEWED,
        {
          taskId,
          action: dto.action,
          status: updatedTask.status,
          rating: dto.rating,
        },
      );
    }

    return { report, task: updatedTask };
  }

  // ============================================================
  // 3. PENDING REVIEWS QUEUE
  // ============================================================

  async getPendingReviews(userId: string, page = 1, limit = 10) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    if (!user) {
      throw new NotFoundException("User not found");
    }

    const isSuperAdmin =
      user.role === Role.SUPER_ADMIN || user.role === Role.HR_ADMIN;

    return this.workRepo.findPendingReviews({
      managerEmployeeId: user.employeeProfile?.id,
      departmentId: user.employeeProfile?.departmentId || undefined,
      isSuperAdmin,
      page,
      limit,
    });
  }

  // ============================================================
  // 4. DEPARTMENT WORKLOAD & CAPACITY
  // ============================================================

  async getDepartmentWorkload(query: QueryWorkloadDto, userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    let targetDeptId = query.departmentId;

    if (!targetDeptId && user?.role === Role.SUPERVISOR) {
      targetDeptId = user.employeeProfile?.departmentId || undefined;
    }

    return this.workRepo.getDepartmentWorkload(targetDeptId);
  }

  // ============================================================
  // 5. ON-DEMAND OVERDUE SCANNER
  // ============================================================

  async checkOverdueTasks() {
    const result = await this.workRepo.markOverdueTasks();
    this.logger.log(
      `Overdue check completed: marked ${result.count} tasks as OVERDUE.`,
    );
    return {
      message: "Overdue scan completed successfully",
      updatedCount: result.count,
    };
  }
}
