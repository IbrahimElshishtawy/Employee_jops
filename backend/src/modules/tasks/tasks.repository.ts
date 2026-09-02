import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { Prisma, Task, TaskStatus } from "@prisma/client";
import {
  CreateTaskDto,
  QueryTasksDto,
  UpdateTaskDto,
  AddChecklistItemDto,
  UpdateChecklistItemDto,
  CreateTaskCommentDto,
  CreateTaskAttachmentDto,
} from "./dto";

@Injectable()
export class TasksRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createTask(creatorId: string, dto: CreateTaskDto) {
    const { checklist, ...taskData } = dto;

    return this.prisma.task.create({
      data: {
        ...taskData,
        creatorId,
        startDate: taskData.startDate ? new Date(taskData.startDate) : undefined,
        dueDate: taskData.dueDate ? new Date(taskData.dueDate) : undefined,
        status: TaskStatus.TODO,
        progress: 0,
        checklist: checklist && checklist.length > 0
          ? {
              create: checklist.map((item, idx) => ({
                title: item.title,
                orderIndex: item.orderIndex ?? idx,
              })),
            }
          : undefined,
        history: {
          create: {
            userId: creatorId,
            action: "TASK_CREATED",
            newStatus: TaskStatus.TODO,
            comment: "Task created",
          },
        },
      },
      include: {
        checklist: { orderBy: { orderIndex: "asc" } },
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
        creator: {
          select: {
            id: true,
            email: true,
            role: true,
          },
        },
        department: {
          select: {
            id: true,
            name: true,
            code: true,
          },
        },
      },
    });
  }

  async findTaskById(id: string) {
    return this.prisma.task.findUnique({
      where: { id },
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
            managerId: true,
            manager: {
              select: {
                id: true,
                userId: true,
                firstName: true,
                lastName: true,
              },
            },
            departmentRel: {
              select: {
                id: true,
                name: true,
                headOfDepartmentId: true,
                headOfDepartment: { select: { userId: true } },
              },
            },
          },
        },
        creator: {
          select: {
            id: true,
            email: true,
            role: true,
            employeeProfile: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
              },
            },
          },
        },
        department: {
          select: {
            id: true,
            name: true,
            code: true,
            headOfDepartmentId: true,
          },
        },
        workplace: {
          select: {
            id: true,
            name: true,
            code: true,
          },
        },
        checklist: {
          orderBy: { orderIndex: "asc" },
        },
        comments: {
          orderBy: { createdAt: "desc" },
          include: {
            author: {
              select: {
                id: true,
                email: true,
                role: true,
                employeeProfile: {
                  select: { firstName: true, lastName: true },
                },
              },
            },
          },
        },
        attachments: {
          orderBy: { createdAt: "desc" },
          include: {
            uploadedBy: {
              select: {
                id: true,
                email: true,
              },
            },
          },
        },
        reports: {
          orderBy: { createdAt: "desc" },
          include: {
            employee: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                employeeCode: true,
              },
            },
            reviewedBy: {
              select: {
                id: true,
                email: true,
              },
            },
          },
        },
        history: {
          orderBy: { createdAt: "desc" },
        },
      },
    });
  }

  async findTasksWithFilters(query: QueryTasksDto) {
    const {
      page = 1,
      limit = 10,
      status,
      priority,
      assigneeId,
      creatorId,
      departmentId,
      workplaceId,
      isOverdue,
      startDate,
      endDate,
      search,
    } = query;

    const skip = (page - 1) * limit;
    const where: Prisma.TaskWhereInput = {};

    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (assigneeId) where.assigneeId = assigneeId;
    if (creatorId) where.creatorId = creatorId;
    if (departmentId) where.departmentId = departmentId;
    if (workplaceId) where.workplaceId = workplaceId;

    if (isOverdue) {
      where.dueDate = { lt: new Date() };
      where.status = {
        notIn: [TaskStatus.COMPLETED, TaskStatus.CANCELLED],
      };
    }

    if (startDate || endDate) {
      where.dueDate = {
        ...(where.dueDate as Prisma.DateTimeNullableFilter),
        ...(startDate ? { gte: new Date(startDate) } : {}),
        ...(endDate ? { lte: new Date(endDate) } : {}),
      };
    }

    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, data] = await Promise.all([
      this.prisma.task.count({ where }),
      this.prisma.task.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          title: true,
          description: true,
          status: true,
          priority: true,
          progress: true,
          startDate: true,
          dueDate: true,
          completedAt: true,
          createdAt: true,
          updatedAt: true,
          assignee: {
            select: {
              id: true,
              employeeCode: true,
              firstName: true,
              lastName: true,
              jobTitle: true,
              department: true,
            },
          },
          creator: {
            select: {
              id: true,
              email: true,
              role: true,
            },
          },
          department: {
            select: {
              id: true,
              name: true,
              code: true,
            },
          },
          _count: {
            select: {
              checklist: true,
              comments: true,
              attachments: true,
              reports: true,
            },
          },
        },
      }),
    ]);

    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async updateTask(id: string, data: Prisma.TaskUpdateInput) {
    return this.prisma.task.update({
      where: { id },
      data,
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
  }

  async deleteTask(id: string) {
    return this.prisma.task.delete({
      where: { id },
    });
  }

  // Checklist methods
  async addChecklistItem(taskId: string, dto: AddChecklistItemDto) {
    return this.prisma.taskChecklistItem.create({
      data: {
        taskId,
        title: dto.title,
        orderIndex: dto.orderIndex ?? 0,
      },
    });
  }

  async findChecklistItem(id: string) {
    return this.prisma.taskChecklistItem.findUnique({
      where: { id },
    });
  }

  async updateChecklistItem(id: string, dto: UpdateChecklistItemDto, userId?: string) {
    const data: Prisma.TaskChecklistItemUpdateInput = {};
    if (dto.title !== undefined) data.title = dto.title;
    if (dto.orderIndex !== undefined) data.orderIndex = dto.orderIndex;
    if (dto.isCompleted !== undefined) {
      data.isCompleted = dto.isCompleted;
      data.completedAt = dto.isCompleted ? new Date() : null;
      data.completedById = dto.isCompleted ? userId : null;
    }

    return this.prisma.taskChecklistItem.update({
      where: { id },
      data,
    });
  }

  async deleteChecklistItem(id: string) {
    return this.prisma.taskChecklistItem.delete({
      where: { id },
    });
  }

  async getChecklistStats(taskId: string) {
    const [total, completed] = await Promise.all([
      this.prisma.taskChecklistItem.count({ where: { taskId } }),
      this.prisma.taskChecklistItem.count({ where: { taskId, isCompleted: true } }),
    ]);
    return { total, completed };
  }

  // Comments
  async addComment(taskId: string, authorId: string, dto: CreateTaskCommentDto) {
    return this.prisma.taskComment.create({
      data: {
        taskId,
        authorId,
        content: dto.content,
        attachmentUrl: dto.attachmentUrl,
      },
      include: {
        author: {
          select: {
            id: true,
            email: true,
            role: true,
            employeeProfile: {
              select: { firstName: true, lastName: true },
            },
          },
        },
      },
    });
  }

  async findComments(taskId: string) {
    return this.prisma.taskComment.findMany({
      where: { taskId },
      orderBy: { createdAt: "desc" },
      include: {
        author: {
          select: {
            id: true,
            email: true,
            role: true,
            employeeProfile: {
              select: { firstName: true, lastName: true },
            },
          },
        },
      },
    });
  }

  // Attachments
  async addAttachment(taskId: string, uploadedById: string, dto: CreateTaskAttachmentDto) {
    return this.prisma.taskAttachment.create({
      data: {
        taskId,
        uploadedById,
        fileName: dto.fileName,
        fileUrl: dto.fileUrl,
        fileSize: dto.fileSize,
        mimeType: dto.mimeType,
      },
      include: {
        uploadedBy: {
          select: {
            id: true,
            email: true,
          },
        },
      },
    });
  }

  async findAttachments(taskId: string) {
    return this.prisma.taskAttachment.findMany({
      where: { taskId },
      orderBy: { createdAt: "desc" },
    });
  }

  // History & Audit
  async addHistory(
    taskId: string,
    action: string,
    userId?: string,
    oldStatus?: TaskStatus,
    newStatus?: TaskStatus,
    comment?: string,
    metadata?: any,
  ) {
    return this.prisma.taskHistory.create({
      data: {
        taskId,
        userId,
        action,
        oldStatus,
        newStatus,
        comment,
        metadata: metadata ? metadata : undefined,
      },
    });
  }

  async findHistory(taskId: string) {
    return this.prisma.taskHistory.findMany({
      where: { taskId },
      orderBy: { createdAt: "desc" },
    });
  }
}
