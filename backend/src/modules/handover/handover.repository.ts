import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateHandoverDto, QueryHandoversDto } from "./dto";
import { HandoverStatus, Prisma, TaskStatus } from "@prisma/client";

@Injectable()
export class HandoverRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Generates a unique, sequential shift handover number (HO-YYYYMMDD-XXXX)
   */
  async generateHandoverNumber(): Promise<string> {
    const now = new Date();
    const yyyy = now.getFullYear();
    const mm = String(now.getMonth() + 1).padStart(2, "0");
    const dd = String(now.getDate()).padStart(2, "0");
    const prefix = `HO-${yyyy}${mm}${dd}`;

    const count = await this.prisma.shiftHandover.count({
      where: {
        handoverNumber: {
          startsWith: prefix,
        },
      },
    });

    const sequence = String(count + 1).padStart(4, "0");
    return `${prefix}-${sequence}`;
  }

  async findOpenDepartmentTasks(departmentId: string, workplaceId?: string) {
    const where: Prisma.TaskWhereInput = {
      departmentId,
      status: {
        in: [
          TaskStatus.TODO,
          TaskStatus.ACCEPTED,
          TaskStatus.IN_PROGRESS,
          TaskStatus.BLOCKED,
          TaskStatus.OVERDUE,
        ],
      },
    };

    if (workplaceId) {
      where.workplaceId = workplaceId;
    }

    return this.prisma.task.findMany({
      where,
      select: {
        id: true,
        title: true,
        description: true,
        priority: true,
        status: true,
        dueDate: true,
        assignee: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
      },
      take: 50,
      orderBy: { priority: "desc" },
    });
  }

  async createHandover(
    handedOverById: string,
    dto: CreateHandoverDto,
    handoverNumber: string,
    autoCapturedItems: any[] = [],
  ) {
    const shiftDate = new Date(dto.shiftDate);

    // Combine manual items with auto-captured items
    const itemsToCreate: Prisma.ShiftHandoverItemCreateWithoutHandoverInput[] = [];

    if (dto.items && dto.items.length > 0) {
      for (const item of dto.items) {
        itemsToCreate.push({
          title: item.title,
          description: item.description || null,
          category: item.category,
          priority: item.priority,
          task: item.taskId ? { connect: { id: item.taskId } } : undefined,
          serviceRequest: item.serviceRequestId
            ? { connect: { id: item.serviceRequestId } }
            : undefined,
          requiresAction: item.requiresAction !== false,
        });
      }
    }

    for (const autoItem of autoCapturedItems) {
      itemsToCreate.push({
        title: `[Open Task] ${autoItem.title}`,
        description:
          autoItem.description ||
          `Status: ${autoItem.status}, Priority: ${autoItem.priority}`,
        category: "TASK",
        priority: autoItem.priority,
        task: { connect: { id: autoItem.id } },
        requiresAction: true,
      });
    }

    return this.prisma.shiftHandover.create({
      data: {
        handoverNumber,
        shiftDate,
        shiftName: dto.shiftName,
        departmentId: dto.departmentId,
        workplaceId: dto.workplaceId || null,
        scheduleId: dto.scheduleId || null,
        handedOverById,
        receivedById: dto.receivedById || null,
        status: HandoverStatus.PENDING_ACKNOWLEDGEMENT,
        summary: dto.summary,
        notes: dto.notes || null,
        metadata: dto.metadata || Prisma.JsonNull,
        items: itemsToCreate.length > 0 ? { create: itemsToCreate } : undefined,
      },
      include: {
        handedOverBy: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            userId: true,
          },
        },
        receivedBy: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            userId: true,
          },
        },
        department: {
          select: {
            id: true,
            name: true,
            code: true,
          },
        },
        items: true,
      },
    });
  }

  async findHandoverById(id: string) {
    return this.prisma.shiftHandover.findUnique({
      where: { id },
      include: {
        handedOverBy: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            phone: true,
            userId: true,
          },
        },
        receivedBy: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            phone: true,
            userId: true,
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
        schedule: {
          select: {
            id: true,
            name: true,
            startTime: true,
            endTime: true,
          },
        },
        items: {
          include: {
            task: {
              select: {
                id: true,
                title: true,
                status: true,
                priority: true,
              },
            },
            serviceRequest: {
              select: {
                id: true,
                requestNumber: true,
                title: true,
                status: true,
                priority: true,
              },
            },
          },
        },
      },
    });
  }

  async findAll(
    query: QueryHandoversDto,
    departmentId?: string,
    employeeId?: string,
  ) {
    const {
      page = 1,
      limit = 10,
      status,
      departmentId: qDeptId,
      workplaceId,
      handedOverById,
      receivedById,
      shiftDate,
      startDate,
      endDate,
      search,
    } = query;

    const skip = (page - 1) * limit;
    const where: Prisma.ShiftHandoverWhereInput = {};

    if (departmentId) {
      where.departmentId = departmentId;
    } else if (qDeptId) {
      where.departmentId = qDeptId;
    }

    if (employeeId) {
      where.OR = [
        { handedOverById: employeeId },
        { receivedById: employeeId },
      ];
    }

    if (workplaceId) {
      where.workplaceId = workplaceId;
    }

    if (handedOverById) {
      where.handedOverById = handedOverById;
    }

    if (receivedById) {
      where.receivedById = receivedById;
    }

    if (status) {
      where.status = status;
    }

    if (shiftDate) {
      where.shiftDate = new Date(shiftDate);
    } else if (startDate || endDate) {
      where.shiftDate = {};
      if (startDate) {
        where.shiftDate.gte = new Date(startDate);
      }
      if (endDate) {
        where.shiftDate.lte = new Date(endDate);
      }
    }

    if (search) {
      where.OR = [
        { summary: { contains: search, mode: "insensitive" } },
        { notes: { contains: search, mode: "insensitive" } },
        { handoverNumber: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, data] = await Promise.all([
      this.prisma.shiftHandover.count({ where }),
      this.prisma.shiftHandover.findMany({
        where,
        skip,
        take: limit,
        orderBy: { shiftDate: "desc" },
        select: {
          id: true,
          handoverNumber: true,
          shiftDate: true,
          shiftName: true,
          status: true,
          summary: true,
          acknowledgedAt: true,
          createdAt: true,
          handedOverBy: {
            select: {
              id: true,
              employeeCode: true,
              firstName: true,
              lastName: true,
            },
          },
          receivedBy: {
            select: {
              id: true,
              employeeCode: true,
              firstName: true,
              lastName: true,
            },
          },
          department: {
            select: {
              id: true,
              name: true,
              code: true,
            },
          },
          workplace: {
            select: {
              id: true,
              name: true,
            },
          },
          _count: {
            select: {
              items: true,
            },
          },
        },
      }),
    ]);

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async updateHandover(id: string, data: Prisma.ShiftHandoverUpdateInput) {
    return this.prisma.shiftHandover.update({
      where: { id },
      data,
      include: {
        handedOverBy: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            userId: true,
          },
        },
        receivedBy: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            userId: true,
          },
        },
        department: {
          select: {
            id: true,
            name: true,
            code: true,
          },
        },
        items: true,
      },
    });
  }

  async addItem(handoverId: string, item: any) {
    const data: Prisma.ShiftHandoverItemUncheckedCreateInput = {
      handoverId,
      title: item.title,
      description: item.description || null,
      category: item.category,
      priority: item.priority,
      taskId: item.taskId || null,
      serviceRequestId: item.serviceRequestId || null,
      requiresAction: item.requiresAction !== false,
    };
    return this.prisma.shiftHandoverItem.create({ data });
  }
}
