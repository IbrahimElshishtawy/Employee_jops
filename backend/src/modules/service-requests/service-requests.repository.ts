import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateServiceRequestDto, QueryServiceRequestsDto } from "./dto";
import { Prisma, ServiceRequestStatus } from "@prisma/client";

@Injectable()
export class ServiceRequestsRepository {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Generates a sequential, human-readable service request number (SR-YYYYMMDD-XXXX)
   */
  async generateRequestNumber(): Promise<string> {
    const now = new Date();
    const yyyy = now.getFullYear();
    const mm = String(now.getMonth() + 1).padStart(2, "0");
    const dd = String(now.getDate()).padStart(2, "0");
    const prefix = `SR-${yyyy}${mm}${dd}`;

    const count = await this.prisma.serviceRequest.count({
      where: {
        requestNumber: {
          startsWith: prefix,
        },
      },
    });

    const sequence = String(count + 1).padStart(4, "0");
    return `${prefix}-${sequence}`;
  }

  async createServiceRequest(
    requesterId: string,
    dto: CreateServiceRequestDto,
    requestNumber: string,
    workflowId?: string | null,
  ) {
    return this.prisma.serviceRequest.create({
      data: {
        requestNumber,
        title: dto.title,
        description: dto.description,
        category: dto.category,
        priority: dto.priority,
        status: ServiceRequestStatus.SUBMITTED,
        requesterId,
        departmentId: dto.departmentId,
        location: dto.location,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        workflowId: workflowId || null,
        metadata: dto.metadata || Prisma.JsonNull,
      },
      include: {
        requester: {
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
        assignedTo: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            userId: true,
          },
        },
      },
    });
  }

  async findServiceRequestById(id: string) {
    return this.prisma.serviceRequest.findUnique({
      where: { id },
      include: {
        requester: {
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
        assignedTo: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            userId: true,
            jobTitle: true,
          },
        },
        workflow: {
          select: {
            id: true,
            name: true,
          },
        },
        history: {
          orderBy: { createdAt: "desc" },
          take: 50,
        },
        comments: {
          orderBy: { createdAt: "asc" },
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
      },
    });
  }

  async findAll(
    query: QueryServiceRequestsDto,
    requesterId?: string,
    departmentId?: string,
  ) {
    const {
      page = 1,
      limit = 10,
      status,
      priority,
      category,
      departmentId: qDeptId,
      requesterId: qReqId,
      assignedToId,
      search,
      startDate,
      endDate,
    } = query;

    const skip = (page - 1) * limit;
    const where: Prisma.ServiceRequestWhereInput = {};

    if (requesterId) {
      where.requesterId = requesterId;
    } else if (qReqId) {
      where.requesterId = qReqId;
    }

    if (departmentId) {
      where.departmentId = departmentId;
    } else if (qDeptId) {
      where.departmentId = qDeptId;
    }

    if (status) {
      where.status = status;
    }

    if (priority) {
      where.priority = priority;
    }

    if (category) {
      where.category = category;
    }

    if (assignedToId) {
      where.assignedToId = assignedToId;
    }

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        where.createdAt.gte = new Date(startDate);
      }
      if (endDate) {
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);
        where.createdAt.lte = end;
      }
    }

    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
        { requestNumber: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, data] = await Promise.all([
      this.prisma.serviceRequest.count({ where }),
      this.prisma.serviceRequest.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          requestNumber: true,
          title: true,
          category: true,
          priority: true,
          status: true,
          location: true,
          dueDate: true,
          completedAt: true,
          closedAt: true,
          reviewRating: true,
          createdAt: true,
          requester: {
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
          assignedTo: {
            select: {
              id: true,
              employeeCode: true,
              firstName: true,
              lastName: true,
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

  async updateServiceRequest(
    id: string,
    data: Prisma.ServiceRequestUpdateInput,
  ) {
    return this.prisma.serviceRequest.update({
      where: { id },
      data,
      include: {
        requester: {
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
        assignedTo: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            userId: true,
          },
        },
      },
    });
  }

  async addHistory(
    serviceRequestId: string,
    actorId: string,
    action: string,
    oldStatus?: ServiceRequestStatus | null,
    newStatus?: ServiceRequestStatus | null,
    notes?: string | null,
    metadata?: any,
  ) {
    return this.prisma.serviceRequestHistory.create({
      data: {
        serviceRequestId,
        actorId,
        action,
        oldStatus: oldStatus || null,
        newStatus: newStatus || null,
        notes: notes || null,
        metadata: metadata || Prisma.JsonNull,
      },
    });
  }

  async addComment(
    serviceRequestId: string,
    authorId: string,
    content: string,
    attachmentUrl?: string | null,
    isInternal = false,
  ) {
    return this.prisma.serviceRequestComment.create({
      data: {
        serviceRequestId,
        authorId,
        content,
        attachmentUrl: attachmentUrl || null,
        isInternal,
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
}
