import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateOnboardingWorkflowDto } from "./dto/create-onboarding-workflow.dto";
import { UpdateOnboardingWorkflowDto } from "./dto/update-onboarding-workflow.dto";
import { CreateOnboardingTaskDto } from "./dto/create-onboarding-task.dto";
import { UpdateOnboardingTaskDto } from "./dto/update-onboarding-task.dto";
import { CompleteOnboardingTaskDto } from "./dto/complete-onboarding-task.dto";
import { QueryOnboardingWorkflowsDto } from "./dto/query-onboarding.dto";
import {
  AuditAction,
  OnboardingStatus,
  OnboardingTaskCategory,
  Prisma,
} from "@prisma/client";

@Injectable()
export class OnboardingService {
  constructor(private prisma: PrismaService) {}

  /**
   * Create an onboarding workflow for an employee
   */
  async createWorkflow(
    dto: CreateOnboardingWorkflowDto,
    userId?: string,
  ) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.employeeId },
      include: { onboardingWorkflow: true },
    });
    if (!employee) {
      throw new NotFoundException(
        `Employee profile #${dto.employeeId} not found`,
      );
    }
    if (employee.onboardingWorkflow) {
      throw new ConflictException(
        "An onboarding workflow already exists for this employee",
      );
    }

    const startDate = dto.startDate ? new Date(dto.startDate) : new Date();
    const targetDate = dto.targetDate
      ? new Date(dto.targetDate)
      : new Date(startDate.getTime() + 30 * 24 * 60 * 60 * 1000);

    const workflow = await this.prisma.onboardingWorkflow.create({
      data: {
        employeeId: dto.employeeId,
        startDate,
        targetDate,
        status: dto.status || OnboardingStatus.PENDING,
        createdById: userId,
        tasks: {
          create: [
            {
              title: "Submit National ID / Passport Copy",
              description:
                "Provide verified identification document copy to HR",
              category: OnboardingTaskCategory.DOCUMENTATION,
              isMandatory: true,
              orderIndex: 1,
            },
            {
              title: "Sign Employment Contract & NDA",
              description:
                "Review and physically/digitally sign the corporate employment agreement",
              category: OnboardingTaskCategory.DOCUMENTATION,
              isMandatory: true,
              orderIndex: 2,
            },
            {
              title: "Workstation & Corporate Credentials Setup",
              description:
                "Assign laptop, email accounts, VPN tokens, and developer access",
              category: OnboardingTaskCategory.IT_SETUP,
              isMandatory: true,
              orderIndex: 3,
            },
            {
              title: "Workplace Geofence & Mobile App Registration",
              description:
                "Download CyberWise mobile app and verify GPS/Beacon check-in",
              category: OnboardingTaskCategory.ORIENTATION,
              isMandatory: true,
              orderIndex: 4,
            },
            {
              title: "Information Security & Compliance Training",
              description:
                "Complete mandatory security and data protection awareness modules",
              category: OnboardingTaskCategory.COMPLIANCE,
              isMandatory: true,
              orderIndex: 5,
            },
            {
              title: "Team & Manager Orientation",
              description:
                "Initial 1:1 meeting with reporting manager and squad team introductions",
              category: OnboardingTaskCategory.ORIENTATION,
              isMandatory: false,
              orderIndex: 6,
            },
          ],
        },
      },
      include: {
        tasks: { orderBy: { orderIndex: "asc" } },
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            department: true,
          },
        },
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.ONBOARDING_WORKFLOW_STARTED,
        entity: "OnboardingWorkflow",
        entityId: workflow.id,
        payload: { employeeId: dto.employeeId },
      },
    });

    return workflow;
  }

  /**
   * List all onboarding workflows (HR Dashboard)
   */
  async getWorkflows(query: QueryOnboardingWorkflowsDto) {
    const { skip, limit, status, employeeId, search } = query;

    const where: Prisma.OnboardingWorkflowWhereInput = {
      ...(status && { status }),
      ...(employeeId && { employeeId }),
      ...(search && {
        employee: {
          OR: [
            { firstName: { contains: search, mode: "insensitive" } },
            { lastName: { contains: search, mode: "insensitive" } },
            { employeeCode: { contains: search, mode: "insensitive" } },
          ],
        },
      }),
    };

    const [total, data] = await Promise.all([
      this.prisma.onboardingWorkflow.count({ where }),
      this.prisma.onboardingWorkflow.findMany({
        where,
        skip,
        take: limit,
        include: {
          employee: {
            select: {
              id: true,
              employeeCode: true,
              firstName: true,
              lastName: true,
              jobTitle: true,
              department: true,
              hireDate: true,
              isProfileComplete: true,
            },
          },
          tasks: {
            select: {
              id: true,
              title: true,
              category: true,
              isMandatory: true,
              isCompleted: true,
            },
            orderBy: { orderIndex: "asc" },
          },
        },
        orderBy: { createdAt: "desc" },
      }),
    ]);

    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get employee self-service onboarding workflow
   */
  async getMyWorkflow(userId: string) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { userId },
    });
    if (!employee) {
      throw new NotFoundException("Employee profile not found");
    }

    const workflow = await this.prisma.onboardingWorkflow.findUnique({
      where: { employeeId: employee.id },
      include: {
        tasks: {
          orderBy: { orderIndex: "asc" },
        },
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            department: true,
            workplace: true,
            schedule: true,
            manager: {
              select: {
                firstName: true,
                lastName: true,
                jobTitle: true,
              },
            },
          },
        },
      },
    });

    if (!workflow) {
      throw new NotFoundException(
        "No active onboarding workflow assigned to your profile",
      );
    }

    return workflow;
  }

  /**
   * Get onboarding workflow by ID
   */
  async getWorkflowById(id: string) {
    const workflow = await this.prisma.onboardingWorkflow.findUnique({
      where: { id },
      include: {
        employee: {
          include: {
            organization: true,
            branch: true,
            departmentRel: true,
            position: true,
            workplace: true,
            schedule: true,
            manager: true,
            documents: true,
          },
        },
        tasks: {
          orderBy: { orderIndex: "asc" },
        },
      },
    });

    if (!workflow) {
      throw new NotFoundException(`Onboarding workflow #${id} not found`);
    }

    return workflow;
  }

  /**
   * Update workflow dates or status
   */
  async updateWorkflow(
    id: string,
    dto: UpdateOnboardingWorkflowDto,
    userId?: string,
  ) {
    const existing = await this.prisma.onboardingWorkflow.findUnique({
      where: { id },
    });
    if (!existing) {
      throw new NotFoundException(`Onboarding workflow #${id} not found`);
    }

    const updated = await this.prisma.onboardingWorkflow.update({
      where: { id },
      data: {
        ...(dto.status && { status: dto.status }),
        ...(dto.startDate && { startDate: new Date(dto.startDate) }),
        ...(dto.targetDate && { targetDate: new Date(dto.targetDate) }),
        ...(dto.completedAt && { completedAt: new Date(dto.completedAt) }),
      },
      include: {
        tasks: { orderBy: { orderIndex: "asc" } },
      },
    });

    return updated;
  }

  /**
   * Add custom task to an onboarding workflow
   */
  async createTask(dto: CreateOnboardingTaskDto, userId?: string) {
    const workflow = await this.prisma.onboardingWorkflow.findUnique({
      where: { id: dto.workflowId },
    });
    if (!workflow) {
      throw new NotFoundException(
        `Onboarding workflow #${dto.workflowId} not found`,
      );
    }

    const task = await this.prisma.onboardingTask.create({
      data: {
        workflowId: dto.workflowId,
        title: dto.title,
        description: dto.description,
        category: dto.category || OnboardingTaskCategory.DOCUMENTATION,
        isMandatory: dto.isMandatory !== undefined ? dto.isMandatory : true,
        assignedToUserId: dto.assignedToUserId,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        orderIndex: dto.orderIndex || 0,
        notes: dto.notes,
      },
    });

    // Recalculate workflow progress
    await this.recalculateWorkflowProgress(dto.workflowId);

    return task;
  }

  /**
   * Update task metadata
   */
  async updateTask(
    taskId: string,
    dto: UpdateOnboardingTaskDto,
    userId?: string,
  ) {
    const task = await this.prisma.onboardingTask.findUnique({
      where: { id: taskId },
    });
    if (!task) {
      throw new NotFoundException(`Onboarding task #${taskId} not found`);
    }

    const updated = await this.prisma.onboardingTask.update({
      where: { id: taskId },
      data: {
        ...(dto.title && { title: dto.title }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.category && { category: dto.category }),
        ...(dto.isMandatory !== undefined && { isMandatory: dto.isMandatory }),
        ...(dto.assignedToUserId !== undefined && {
          assignedToUserId: dto.assignedToUserId,
        }),
        ...(dto.dueDate !== undefined && {
          dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        }),
        ...(dto.orderIndex !== undefined && { orderIndex: dto.orderIndex }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
      },
    });

    await this.recalculateWorkflowProgress(task.workflowId);

    return updated;
  }

  /**
   * Complete or uncomplete an onboarding task
   */
  async completeTask(
    taskId: string,
    dto: CompleteOnboardingTaskDto,
    currentUserId: string,
  ) {
    const task = await this.prisma.onboardingTask.findUnique({
      where: { id: taskId },
      include: { workflow: true },
    });
    if (!task) {
      throw new NotFoundException(`Onboarding task #${taskId} not found`);
    }

    const updatedTask = await this.prisma.onboardingTask.update({
      where: { id: taskId },
      data: {
        isCompleted: dto.isCompleted,
        completedAt: dto.isCompleted ? new Date() : null,
        completedById: dto.isCompleted ? currentUserId : null,
        ...(dto.notes && { notes: dto.notes }),
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: currentUserId,
        action: dto.isCompleted
          ? AuditAction.ONBOARDING_TASK_COMPLETED
          : AuditAction.ONBOARDING_TASK_UPDATED,
        entity: "OnboardingTask",
        entityId: taskId,
        payload: {
          taskTitle: task.title,
          isCompleted: dto.isCompleted,
        },
      },
    });

    // Recalculate progress & potentially auto-complete workflow
    const updatedWorkflow = await this.recalculateWorkflowProgress(
      task.workflowId,
      currentUserId,
    );

    return {
      task: updatedTask,
      workflow: updatedWorkflow,
    };
  }

  /**
   * Manually finalize an onboarding workflow
   */
  async finalizeWorkflow(workflowId: string, userId: string) {
    const workflow = await this.prisma.onboardingWorkflow.findUnique({
      where: { id: workflowId },
      include: { tasks: true },
    });
    if (!workflow) {
      throw new NotFoundException(
        `Onboarding workflow #${workflowId} not found`,
      );
    }

    const now = new Date();

    // Mark all tasks as completed
    await this.prisma.onboardingTask.updateMany({
      where: { workflowId, isCompleted: false },
      data: {
        isCompleted: true,
        completedAt: now,
        completedById: userId,
      },
    });

    const updatedWorkflow = await this.prisma.onboardingWorkflow.update({
      where: { id: workflowId },
      data: {
        status: OnboardingStatus.COMPLETED,
        progressPercentage: 100,
        completedAt: now,
      },
    });

    // Update EmployeeProfile onboarding completed timestamp
    await this.prisma.employeeProfile.update({
      where: { id: workflow.employeeId },
      data: {
        onboardingCompletedAt: now,
        isProfileComplete: true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.ONBOARDING_WORKFLOW_COMPLETED,
        entity: "OnboardingWorkflow",
        entityId: workflowId,
        payload: { employeeId: workflow.employeeId },
      },
    });

    return updatedWorkflow;
  }

  /**
   * Delete an onboarding task
   */
  async deleteTask(taskId: string, userId?: string) {
    const task = await this.prisma.onboardingTask.findUnique({
      where: { id: taskId },
    });
    if (!task) {
      throw new NotFoundException(`Onboarding task #${taskId} not found`);
    }

    await this.prisma.onboardingTask.delete({ where: { id: taskId } });

    await this.recalculateWorkflowProgress(task.workflowId);

    return { message: "Task deleted successfully" };
  }

  /**
   * Helper: Calculates completion percentage and updates workflow state
   */
  private async recalculateWorkflowProgress(
    workflowId: string,
    currentUserId?: string,
  ) {
    const tasks = await this.prisma.onboardingTask.findMany({
      where: { workflowId },
    });

    if (tasks.length === 0) {
      return this.prisma.onboardingWorkflow.update({
        where: { id: workflowId },
        data: { progressPercentage: 0 },
      });
    }

    const total = tasks.length;
    const completed = tasks.filter((t) => t.isCompleted).length;
    const mandatoryTotal = tasks.filter((t) => t.isMandatory).length;
    const mandatoryCompleted = tasks.filter(
      (t) => t.isMandatory && t.isCompleted,
    ).length;

    const progressPercentage = Math.round((completed / total) * 100 * 10) / 10;
    const allMandatoryDone =
      mandatoryTotal > 0 ? mandatoryCompleted === mandatoryTotal : completed === total;

    let status: OnboardingStatus = OnboardingStatus.IN_PROGRESS;
    let completedAt: Date | null = null;

    if (completed === 0) {
      status = OnboardingStatus.PENDING;
    } else if (allMandatoryDone && completed === total) {
      status = OnboardingStatus.COMPLETED;
      completedAt = new Date();
    }

    const workflow = await this.prisma.onboardingWorkflow.update({
      where: { id: workflowId },
      data: {
        progressPercentage,
        status,
        ...(completedAt && { completedAt }),
      },
    });

    // If fully completed, update EmployeeProfile
    if (status === OnboardingStatus.COMPLETED) {
      await this.prisma.employeeProfile.update({
        where: { id: workflow.employeeId },
        data: {
          onboardingCompletedAt: completedAt,
          isProfileComplete: true,
        },
      });

      await this.prisma.auditLog.create({
        data: {
          userId: currentUserId,
          action: AuditAction.ONBOARDING_WORKFLOW_COMPLETED,
          entity: "OnboardingWorkflow",
          entityId: workflowId,
          payload: { employeeId: workflow.employeeId },
        },
      });
    }

    return workflow;
  }
}
