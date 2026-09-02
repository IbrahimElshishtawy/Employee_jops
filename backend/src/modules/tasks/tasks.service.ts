import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from "@nestjs/common";
import { TasksRepository } from "./tasks.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  CreateTaskDto,
  UpdateTaskDto,
  QueryTasksDto,
  AssignTaskDto,
  UpdateTaskStatusDto,
  AddChecklistItemDto,
  UpdateChecklistItemDto,
  CreateTaskCommentDto,
  CreateTaskAttachmentDto,
} from "./dto";
import {
  AuditAction,
  NotificationType,
  Role,
  TaskPriority,
  TaskStatus,
  UserStatus,
} from "@prisma/client";

@Injectable()
export class TasksService {
  private readonly logger = new Logger(TasksService.name);

  constructor(
    private readonly tasksRepo: TasksRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ============================================================
  // 1. CREATE TASK & ASSIGNMENT
  // ============================================================

  async createTask(creatorId: string, dto: CreateTaskDto) {
    if (dto.assigneeId) {
      const assignee = await this.prisma.employeeProfile.findUnique({
        where: { id: dto.assigneeId },
        include: { user: true },
      });
      if (!assignee || (assignee.user && assignee.user.status !== UserStatus.ACTIVE)) {
        throw new BadRequestException("Assignee employee not found or inactive");
      }
    }

    if (dto.departmentId) {
      const dept = await this.prisma.department.findUnique({
        where: { id: dto.departmentId },
      });
      if (!dept) {
        throw new BadRequestException("Department not found");
      }
    }

    if (dto.startDate && dto.dueDate) {
      if (new Date(dto.startDate) > new Date(dto.dueDate)) {
        throw new BadRequestException("Start date cannot be after due date");
      }
    }

    const task = await this.tasksRepo.createTask(creatorId, dto);

    // Audit Log
    await this.prisma.auditLog.create({
      data: {
        userId: creatorId,
        action: AuditAction.TASK_CREATED,
        entity: "Task",
        entityId: task.id,
        payload: {
          title: task.title,
          priority: task.priority,
          assigneeId: task.assigneeId,
        },
      },
    });

    // Notify assignee if assigned
    if (task.assignee?.userId && task.assignee.userId !== creatorId) {
      await this.notificationsService.sendNotification(
        task.assignee.userId,
        "New Task Assigned",
        `You have been assigned to task: "${task.title}"`,
        NotificationType.TASK_ASSIGNED,
        { taskId: task.id, priority: task.priority },
      );
    }

    return task;
  }

  async assignTask(taskId: string, actorUserId: string, dto: AssignTaskDto) {
    const task = await this.tasksRepo.findTaskById(taskId);
    if (!task) {
      throw new NotFoundException(`Task ${taskId} not found`);
    }

    if (task.status === TaskStatus.COMPLETED || task.status === TaskStatus.CANCELLED) {
      throw new BadRequestException(
        `Cannot reassign a task in ${task.status} status`,
      );
    }

    const assignee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.assigneeId },
      include: { user: true },
    });
    if (!assignee || (assignee.user && assignee.user.status !== UserStatus.ACTIVE)) {
      throw new BadRequestException("Assignee employee not found or inactive");
    }

    const oldAssigneeId = task.assigneeId;

    const updated = await this.tasksRepo.updateTask(taskId, {
      assignee: { connect: { id: dto.assigneeId } },
      status: TaskStatus.TODO, // Re-assigned tasks start at TODO for acceptance
    });

    await this.tasksRepo.addHistory(
      taskId,
      "TASK_ASSIGNED",
      actorUserId,
      task.status,
      TaskStatus.TODO,
      dto.notes || `Assigned to ${assignee.firstName} ${assignee.lastName}`,
      { oldAssigneeId, newAssigneeId: dto.assigneeId },
    );

    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: AuditAction.TASK_ASSIGNED,
        entity: "Task",
        entityId: taskId,
        payload: { oldAssigneeId, newAssigneeId: dto.assigneeId },
      },
    });

    if (assignee.userId && assignee.userId !== actorUserId) {
      await this.notificationsService.sendNotification(
        assignee.userId,
        "Task Assigned",
        `You have been assigned to task: "${task.title}"`,
        NotificationType.TASK_ASSIGNED,
        { taskId: task.id },
      );
    }

    return updated;
  }

  // ============================================================
  // 2. EMPLOYEE ACCEPTANCE
  // ============================================================

  async acceptTask(taskId: string, userId: string) {
    const task = await this.tasksRepo.findTaskById(taskId);
    if (!task) {
      throw new NotFoundException(`Task ${taskId} not found`);
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    const isAssignee = task.assignee && task.assignee.userId === userId;
    const isSuperAdmin = user?.role === Role.SUPER_ADMIN;

    if (!isAssignee && !isSuperAdmin) {
      throw new ForbiddenException(
        "Only the assigned employee can accept this task",
      );
    }

    if (task.status !== TaskStatus.TODO) {
      throw new BadRequestException(
        `Task cannot be accepted from status ${task.status}. Must be in TODO status.`,
      );
    }

    const updated = await this.tasksRepo.updateTask(taskId, {
      status: TaskStatus.ACCEPTED,
    });

    await this.tasksRepo.addHistory(
      taskId,
      "TASK_ACCEPTED",
      userId,
      TaskStatus.TODO,
      TaskStatus.ACCEPTED,
      "Task accepted by assignee",
    );

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.TASK_ACCEPTED,
        entity: "Task",
        entityId: taskId,
      },
    });

    if (task.creatorId && task.creatorId !== userId) {
      await this.notificationsService.sendNotification(
        task.creatorId,
        "Task Accepted",
        `${task.assignee?.firstName || "Assignee"} accepted task "${task.title}"`,
        NotificationType.TASK_STATUS_UPDATE,
        { taskId, status: TaskStatus.ACCEPTED },
      );
    }

    return updated;
  }

  // ============================================================
  // 3. STATUS TRANSITIONS & PROGRESS
  // ============================================================

  async updateStatus(taskId: string, userId: string, dto: UpdateTaskStatusDto) {
    const task = await this.tasksRepo.findTaskById(taskId);
    if (!task) {
      throw new NotFoundException(`Task ${taskId} not found`);
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    const isAssignee = Boolean(task.assignee && task.assignee.userId === userId);
    const isCreator = task.creatorId === userId;
    const isManagerOrAdmin = Boolean(
      user?.role === Role.SUPER_ADMIN ||
      user?.role === Role.HR_ADMIN ||
      user?.role === Role.HR_MANAGER ||
      (user?.employeeProfile && task.assignee?.managerId === user.employeeProfile.id),
    );

    if (!isAssignee && !isCreator && !isManagerOrAdmin) {
      throw new ForbiddenException(
        "You do not have authorization to modify the status of this task",
      );
    }

    this.validateStatusTransition(task.status, dto.status, isAssignee, isManagerOrAdmin);

    const updateData: any = {
      status: dto.status,
    };

    if (dto.status === TaskStatus.COMPLETED) {
      updateData.completedAt = new Date();
      updateData.progress = 100;
    } else if (dto.status === TaskStatus.IN_PROGRESS && task.progress === 0) {
      updateData.progress = 10; // Started work
    }

    const updated = await this.tasksRepo.updateTask(taskId, updateData);

    await this.tasksRepo.addHistory(
      taskId,
      "TASK_STATUS_CHANGED",
      userId,
      task.status,
      dto.status,
      dto.reason || `Status updated from ${task.status} to ${dto.status}`,
    );

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.TASK_STATUS_CHANGED,
        entity: "Task",
        entityId: taskId,
        payload: { oldStatus: task.status, newStatus: dto.status, reason: dto.reason },
      },
    });

    // Notify counterpart
    const notifyTarget = isAssignee ? task.creatorId : task.assignee?.userId;
    if (notifyTarget && notifyTarget !== userId) {
      await this.notificationsService.sendNotification(
        notifyTarget,
        "Task Status Updated",
        `Task "${task.title}" status changed to ${dto.status}`,
        NotificationType.TASK_STATUS_UPDATE,
        { taskId, status: dto.status },
      );
    }

    return updated;
  }

  private validateStatusTransition(
    current: TaskStatus,
    target: TaskStatus,
    isAssignee: boolean,
    isManagerOrAdmin: boolean,
  ) {
    if (current === target) {
      throw new BadRequestException(`Task is already in status ${current}`);
    }

    // Terminal states cannot be changed except by Manager/Admin
    if ((current === TaskStatus.COMPLETED || current === TaskStatus.CANCELLED) && !isManagerOrAdmin) {
      throw new BadRequestException(
        `Only managers or administrators can reopen a ${current} task`,
      );
    }

    // Valid state transitions
    const transitions: Record<TaskStatus, TaskStatus[]> = {
      [TaskStatus.TODO]: [TaskStatus.ACCEPTED, TaskStatus.IN_PROGRESS, TaskStatus.CANCELLED],
      [TaskStatus.ACCEPTED]: [TaskStatus.IN_PROGRESS, TaskStatus.BLOCKED, TaskStatus.CANCELLED],
      [TaskStatus.IN_PROGRESS]: [
        TaskStatus.BLOCKED,
        TaskStatus.PENDING_REVIEW,
        TaskStatus.COMPLETED,
        TaskStatus.CANCELLED,
      ],
      [TaskStatus.BLOCKED]: [TaskStatus.IN_PROGRESS, TaskStatus.CANCELLED],
      [TaskStatus.PENDING_REVIEW]: [TaskStatus.COMPLETED, TaskStatus.IN_PROGRESS, TaskStatus.CANCELLED],
      [TaskStatus.OVERDUE]: [TaskStatus.IN_PROGRESS, TaskStatus.COMPLETED, TaskStatus.CANCELLED],
      [TaskStatus.COMPLETED]: [TaskStatus.IN_PROGRESS],
      [TaskStatus.CANCELLED]: [TaskStatus.TODO, TaskStatus.IN_PROGRESS],
    };

    const allowed = transitions[current] || [];
    if (!allowed.includes(target)) {
      throw new BadRequestException(
        `Invalid status transition from ${current} to ${target}`,
      );
    }

    // Employee cannot directly approve from PENDING_REVIEW to COMPLETED
    if (current === TaskStatus.PENDING_REVIEW && target === TaskStatus.COMPLETED && !isManagerOrAdmin) {
      throw new ForbiddenException(
        "Only managers or supervisors can approve tasks in PENDING_REVIEW",
      );
    }
  }

  async updateTask(taskId: string, userId: string, dto: UpdateTaskDto) {
    const task = await this.tasksRepo.findTaskById(taskId);
    if (!task) {
      throw new NotFoundException(`Task ${taskId} not found`);
    }

    const updateData: any = {
      ...dto,
      startDate: dto.startDate ? new Date(dto.startDate) : undefined,
      dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
    };
    delete updateData.checklist;

    const updated = await this.tasksRepo.updateTask(taskId, updateData);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.TASK_UPDATED,
        entity: "Task",
        entityId: taskId,
        payload: { changes: dto as any },
      },
    });

    return updated;
  }

  // ============================================================
  // 4. CHECKLIST MANAGEMENT & AUTO-PROGRESS
  // ============================================================

  async addChecklistItem(taskId: string, userId: string, dto: AddChecklistItemDto) {
    const task = await this.tasksRepo.findTaskById(taskId);
    if (!task) {
      throw new NotFoundException(`Task ${taskId} not found`);
    }

    const item = await this.tasksRepo.addChecklistItem(taskId, dto);
    await this.recalculateChecklistProgress(taskId);

    return item;
  }

  async updateChecklistItem(
    taskId: string,
    itemId: string,
    userId: string,
    dto: UpdateChecklistItemDto,
  ) {
    const item = await this.tasksRepo.findChecklistItem(itemId);
    if (!item || item.taskId !== taskId) {
      throw new NotFoundException(`Checklist item ${itemId} not found on task`);
    }

    const updated = await this.tasksRepo.updateChecklistItem(itemId, dto, userId);
    await this.recalculateChecklistProgress(taskId);

    return updated;
  }

  async deleteChecklistItem(taskId: string, itemId: string) {
    const item = await this.tasksRepo.findChecklistItem(itemId);
    if (!item || item.taskId !== taskId) {
      throw new NotFoundException(`Checklist item ${itemId} not found on task`);
    }

    const deleted = await this.tasksRepo.deleteChecklistItem(itemId);
    await this.recalculateChecklistProgress(taskId);

    return deleted;
  }

  private async recalculateChecklistProgress(taskId: string) {
    const stats = await this.tasksRepo.getChecklistStats(taskId);
    if (stats.total === 0) return;

    const calculatedProgress = Math.round((stats.completed / stats.total) * 100);
    await this.tasksRepo.updateTask(taskId, {
      progress: calculatedProgress,
    });
  }

  // ============================================================
  // 5. COMMENTS & ATTACHMENTS
  // ============================================================

  async addComment(taskId: string, userId: string, dto: CreateTaskCommentDto) {
    const task = await this.tasksRepo.findTaskById(taskId);
    if (!task) {
      throw new NotFoundException(`Task ${taskId} not found`);
    }

    const comment = await this.tasksRepo.addComment(taskId, userId, dto);

    // Notify relevant counterpart
    const targetUserId = task.creatorId === userId ? task.assignee?.userId : task.creatorId;
    if (targetUserId && targetUserId !== userId) {
      await this.notificationsService.sendNotification(
        targetUserId,
        "New Task Comment",
        `New comment on "${task.title}": ${dto.content.slice(0, 50)}...`,
        NotificationType.TASK_STATUS_UPDATE,
        { taskId, commentId: comment.id },
      );
    }

    return comment;
  }

  async getComments(taskId: string) {
    return this.tasksRepo.findComments(taskId);
  }

  async addAttachment(taskId: string, userId: string, dto: CreateTaskAttachmentDto) {
    const task = await this.tasksRepo.findTaskById(taskId);
    if (!task) {
      throw new NotFoundException(`Task ${taskId} not found`);
    }

    return this.tasksRepo.addAttachment(taskId, userId, dto);
  }

  async getAttachments(taskId: string) {
    return this.tasksRepo.findAttachments(taskId);
  }

  // ============================================================
  // 6. QUERIES & DETAILS
  // ============================================================

  async findOne(taskId: string) {
    const task = await this.tasksRepo.findTaskById(taskId);
    if (!task) {
      throw new NotFoundException(`Task ${taskId} not found`);
    }

    // Dynamic overdue evaluation: if due date passed and not completed/cancelled
    const isPastDue =
      task.dueDate &&
      new Date() > new Date(task.dueDate) &&
      task.status !== TaskStatus.COMPLETED &&
      task.status !== TaskStatus.CANCELLED;

    return {
      ...task,
      isOverdue: isPastDue,
    };
  }

  async findAll(query: QueryTasksDto) {
    return this.tasksRepo.findTasksWithFilters(query);
  }

  async getMyTasks(userId: string, query: QueryTasksDto) {
    const userEmployee = await this.prisma.employeeProfile.findUnique({
      where: { userId },
      select: { id: true },
    });

    if (userEmployee) {
      query.assigneeId = userEmployee.id;
    } else {
      query.creatorId = userId;
    }

    return this.tasksRepo.findTasksWithFilters(query);
  }

  async getTaskHistory(taskId: string) {
    return this.tasksRepo.findHistory(taskId);
  }

  async deleteTask(taskId: string, userId: string) {
    const task = await this.tasksRepo.findTaskById(taskId);
    if (!task) {
      throw new NotFoundException(`Task ${taskId} not found`);
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (
      user?.role !== Role.SUPER_ADMIN &&
      user?.role !== Role.HR_ADMIN &&
      task.creatorId !== userId
    ) {
      throw new ForbiddenException(
        "Only task creator or administrators can delete this task",
      );
    }

    const deleted = await this.tasksRepo.deleteTask(taskId);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.TASK_DELETED,
        entity: "Task",
        entityId: taskId,
        payload: { title: task.title },
      },
    });

    return deleted;
  }
}
