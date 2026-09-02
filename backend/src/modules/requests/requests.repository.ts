import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { Prisma, RequestStatus, RequestType, Role } from "@prisma/client";
import { CreateLeaveBalanceDto, CreateRequestDto, QueryRequestsDto } from "./dto";

@Injectable()
export class RequestsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findByIdempotencyKey(idempotencyKey: string) {
    return this.prisma.request.findUnique({
      where: { idempotencyKey },
      include: {
        approvalSteps: {
          include: {
            approver: {
              select: { id: true, email: true, role: true },
            },
          },
        },
      },
    });
  }

  async findConflictingApproved(employeeId: string, startDate: Date, endDate: Date) {
    return this.prisma.request.findFirst({
      where: {
        employeeId,
        status: RequestStatus.APPROVED,
        startDate: { lte: endDate },
        endDate: { gte: startDate },
      },
    });
  }

  async create(data: {
    idempotencyKey?: string;
    employeeId: string;
    type: RequestType;
    status: RequestStatus;
    startDate: Date;
    endDate: Date;
    startTime?: string;
    endTime?: string;
    halfDayPeriod?: any;
    reason: string;
    attachmentUrl?: string;
    workflowId?: string | null;
    currentStepOrder?: number;
    totalSteps?: number;
    metadata?: Prisma.InputJsonValue;
  }) {
    return this.prisma.request.create({
      data: {
        idempotencyKey: data.idempotencyKey,
        employeeId: data.employeeId,
        type: data.type,
        status: data.status,
        startDate: data.startDate,
        endDate: data.endDate,
        startTime: data.startTime,
        endTime: data.endTime,
        halfDayPeriod: data.halfDayPeriod,
        reason: data.reason,
        attachmentUrl: data.attachmentUrl,
        workflowId: data.workflowId,
        currentStepOrder: data.currentStepOrder ?? 1,
        totalSteps: data.totalSteps ?? 1,
        metadata: data.metadata,
      },
      include: {
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            department: true,
          },
        },
        workflow: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });
  }

  async findById(requestId: string) {
    return this.prisma.request.findUnique({
      where: { id: requestId },
      include: {
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            department: true,
            workplace: { select: { id: true, name: true, code: true } },
            schedule: {
              select: { id: true, name: true, startTime: true, endTime: true },
            },
          },
        },
        workflow: {
          include: {
            steps: { orderBy: { stepOrder: "asc" } },
          },
        },
        approvalSteps: {
          include: {
            approver: {
              select: {
                id: true,
                email: true,
                role: true,
              },
            },
          },
          orderBy: [{ stepOrder: "asc" }, { createdAt: "asc" }],
        },
      },
    });
  }

  async findMyRequests(employeeProfileId: string, query: Partial<QueryRequestsDto> = {}) {
    const {
      page = 1,
      limit = 10,
      status,
      type,
      startDate,
      endDate,
      search,
      sortBy = "createdAt",
      sortOrder = "desc",
    } = query;

    const skip = (page - 1) * limit;
    const where: Prisma.RequestWhereInput = {
      employeeId: employeeProfileId,
    };

    if (status) where.status = status;
    if (type) where.type = type;

    if (startDate || endDate) {
      where.AND = [];
      if (startDate) {
        (where.AND as any[]).push({
          endDate: { gte: new Date(startDate) },
        });
      }
      if (endDate) {
        (where.AND as any[]).push({
          startDate: { lte: new Date(endDate) },
        });
      }
    }

    if (search) {
      where.reason = { contains: search, mode: "insensitive" };
    }

    const [total, data] = await Promise.all([
      this.prisma.request.count({ where }),
      this.prisma.request.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          approvalSteps: {
            include: {
              approver: {
                select: {
                  id: true,
                  email: true,
                  role: true,
                },
              },
            },
            orderBy: [{ stepOrder: "asc" }, { createdAt: "asc" }],
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

  async findAll(query: Partial<QueryRequestsDto> = {}) {
    const {
      page = 1,
      limit = 10,
      status,
      type,
      employeeId,
      department,
      workplaceId,
      startDate,
      endDate,
      search,
      sortBy = "createdAt",
      sortOrder = "desc",
    } = query;

    const skip = (page - 1) * limit;
    const where: Prisma.RequestWhereInput = {};

    if (status) where.status = status;
    if (type) where.type = type;
    if (employeeId) where.employeeId = employeeId;

    if (department || workplaceId) {
      where.employee = {};
      if (department) where.employee.department = department;
      if (workplaceId) where.employee.workplaceId = workplaceId;
    }

    if (startDate || endDate) {
      where.AND = [];
      if (startDate) {
        (where.AND as any[]).push({
          endDate: { gte: new Date(startDate) },
        });
      }
      if (endDate) {
        (where.AND as any[]).push({
          startDate: { lte: new Date(endDate) },
        });
      }
    }

    if (search) {
      where.OR = [
        { reason: { contains: search, mode: "insensitive" } },
        { employee: { firstName: { contains: search, mode: "insensitive" } } },
        { employee: { lastName: { contains: search, mode: "insensitive" } } },
        { employee: { employeeCode: { contains: search, mode: "insensitive" } } },
      ];
    }

    const [total, data] = await Promise.all([
      this.prisma.request.count({ where }),
      this.prisma.request.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          employee: {
            select: {
              id: true,
              employeeCode: true,
              firstName: true,
              lastName: true,
              jobTitle: true,
              department: true,
              workplace: { select: { id: true, name: true } },
            },
          },
          approvalSteps: {
            include: {
              approver: { select: { id: true, email: true, role: true } },
            },
            orderBy: [{ stepOrder: "asc" }, { createdAt: "asc" }],
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

  async findLeaveBalance(employeeId: string, leaveType: RequestType, year: number) {
    return this.prisma.leaveBalance.findUnique({
      where: {
        employeeId_leaveType_year: {
          employeeId,
          leaveType,
          year,
        },
      },
    });
  }

  async createLeaveBalance(data: {
    employeeId: string;
    leaveType: RequestType;
    year: number;
    totalDays: number;
    usedDays?: number;
    pendingDays?: number;
    remainingDays?: number;
  }) {
    return this.prisma.leaveBalance.create({
      data: {
        employeeId: data.employeeId,
        leaveType: data.leaveType,
        year: data.year,
        totalDays: data.totalDays,
        usedDays: data.usedDays ?? 0,
        pendingDays: data.pendingDays ?? 0,
        remainingDays: data.remainingDays ?? data.totalDays,
      },
    });
  }

  async findLeaveBalancesByEmployee(employeeId: string, year: number) {
    return this.prisma.leaveBalance.findMany({
      where: {
        employeeId,
        year,
      },
      orderBy: { leaveType: "asc" },
    });
  }
}
