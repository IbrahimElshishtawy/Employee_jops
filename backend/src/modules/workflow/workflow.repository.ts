import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { Prisma, RequestType, Role, WorkflowDefinition } from "@prisma/client";
import { CreateWorkflowDto, QueryWorkflowDto, UpdateWorkflowDto } from "./dto";

@Injectable()
export class WorkflowRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateWorkflowDto): Promise<WorkflowDefinition> {
    const { steps, ...rest } = dto;

    return this.prisma.$transaction(async (tx) => {
      // If this workflow is marked as default, unset other defaults for the same requestType
      if (rest.isDefault) {
        await tx.workflowDefinition.updateMany({
          where: {
            requestType: rest.requestType || null,
            isDefault: true,
          },
          data: { isDefault: false },
        });
      }

      return tx.workflowDefinition.create({
        data: {
          name: rest.name,
          description: rest.description,
          requestType: rest.requestType,
          organizationId: rest.organizationId,
          departmentId: rest.departmentId,
          role: rest.role,
          minDays: rest.minDays,
          maxDays: rest.maxDays,
          minAmount: rest.minAmount ? new Prisma.Decimal(rest.minAmount) : null,
          maxAmount: rest.maxAmount ? new Prisma.Decimal(rest.maxAmount) : null,
          priority: rest.priority ?? 0,
          isActive: rest.isActive ?? true,
          isDefault: rest.isDefault ?? false,
          steps: {
            create: steps.map((s) => ({
              stepOrder: s.stepOrder,
              name: s.name,
              approverType: s.approverType,
              role: s.role,
              specificUserId: s.specificUserId,
              isMandatory: s.isMandatory ?? true,
              canDelegate: s.canDelegate ?? true,
              timeoutHours: s.timeoutHours,
              autoApproveOnTimeout: s.autoApproveOnTimeout ?? false,
            })),
          },
        },
        include: {
          steps: {
            orderBy: { stepOrder: "asc" },
          },
        },
      });
    });
  }

  async update(id: string, dto: UpdateWorkflowDto) {
    const { steps, ...rest } = dto;

    return this.prisma.$transaction(async (tx) => {
      if (rest.isDefault) {
        await tx.workflowDefinition.updateMany({
          where: {
            id: { not: id },
            requestType: rest.requestType || null,
            isDefault: true,
          },
          data: { isDefault: false },
        });
      }

      // If new steps are supplied, replace existing steps
      if (steps && steps.length > 0) {
        await tx.workflowStepDefinition.deleteMany({
          where: { workflowId: id },
        });
      }

      const updateData: Prisma.WorkflowDefinitionUpdateInput = {};
      if (rest.name !== undefined) updateData.name = rest.name;
      if (rest.description !== undefined) updateData.description = rest.description;
      if (rest.requestType !== undefined) updateData.requestType = rest.requestType;
      if (rest.organizationId !== undefined) {
        updateData.organization = rest.organizationId
          ? { connect: { id: rest.organizationId } }
          : { disconnect: true };
      }
      if (rest.departmentId !== undefined) {
        updateData.department = rest.departmentId
          ? { connect: { id: rest.departmentId } }
          : { disconnect: true };
      }
      if (rest.role !== undefined) updateData.role = rest.role;
      if (rest.minDays !== undefined) updateData.minDays = rest.minDays;
      if (rest.maxDays !== undefined) updateData.maxDays = rest.maxDays;
      if (rest.minAmount !== undefined) {
        updateData.minAmount = rest.minAmount ? new Prisma.Decimal(rest.minAmount) : null;
      }
      if (rest.maxAmount !== undefined) {
        updateData.maxAmount = rest.maxAmount ? new Prisma.Decimal(rest.maxAmount) : null;
      }
      if (rest.priority !== undefined) updateData.priority = rest.priority;
      if (rest.isActive !== undefined) updateData.isActive = rest.isActive;
      if (rest.isDefault !== undefined) updateData.isDefault = rest.isDefault;

      if (steps && steps.length > 0) {
        updateData.steps = {
          create: steps.map((s) => ({
            stepOrder: s.stepOrder,
            name: s.name,
            approverType: s.approverType,
            role: s.role,
            specificUserId: s.specificUserId,
            isMandatory: s.isMandatory ?? true,
            canDelegate: s.canDelegate ?? true,
            timeoutHours: s.timeoutHours,
            autoApproveOnTimeout: s.autoApproveOnTimeout ?? false,
          })),
        };
      }

      return tx.workflowDefinition.update({
        where: { id },
        data: updateData,
        include: {
          steps: {
            orderBy: { stepOrder: "asc" },
          },
        },
      });
    });
  }

  async findById(id: string) {
    return this.prisma.workflowDefinition.findUnique({
      where: { id },
      include: {
        department: { select: { id: true, name: true, code: true } },
        organization: { select: { id: true, name: true, code: true } },
        steps: {
          orderBy: { stepOrder: "asc" },
        },
      },
    });
  }

  async findAll(query: QueryWorkflowDto) {
    const { page = 1, limit = 10, requestType, departmentId, role, isActive, search } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.WorkflowDefinitionWhereInput = {};
    if (requestType) where.requestType = requestType;
    if (departmentId) where.departmentId = departmentId;
    if (role) where.role = role;
    if (isActive !== undefined) where.isActive = isActive;
    if (search) {
      where.OR = [
        { name: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, data] = await Promise.all([
      this.prisma.workflowDefinition.count({ where }),
      this.prisma.workflowDefinition.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ priority: "desc" }, { createdAt: "desc" }],
        include: {
          department: { select: { id: true, name: true, code: true } },
          steps: {
            orderBy: { stepOrder: "asc" },
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

  async findActiveCandidates(params: {
    requestType?: RequestType;
    departmentId?: string | null;
    role?: Role | null;
  }) {
    return this.prisma.workflowDefinition.findMany({
      where: {
        isActive: true,
        OR: [
          { requestType: params.requestType },
          { requestType: null },
        ],
      },
      include: {
        steps: {
          orderBy: { stepOrder: "asc" },
        },
      },
      orderBy: [{ priority: "desc" }, { createdAt: "desc" }],
    });
  }

  async delete(id: string) {
    return this.prisma.workflowDefinition.delete({
      where: { id },
    });
  }
}
