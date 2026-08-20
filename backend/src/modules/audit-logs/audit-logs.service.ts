import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { PaginationQueryDto } from "../../common/dto/pagination.dto";
import { AuditAction, Prisma } from "@prisma/client";

@Injectable()
export class AuditLogsService {
  constructor(private prisma: PrismaService) {}

  async findAll(
    query: PaginationQueryDto,
    action?: AuditAction,
    entity?: string,
  ) {
    const { skip, limit } = query;
    const where: Prisma.AuditLogWhereInput = {};

    if (action) {
      where.action = action;
    }

    if (entity) {
      where.entity = entity;
    }

    const [total, data] = await Promise.all([
      this.prisma.auditLog.count({ where }),
      this.prisma.auditLog.findMany({
        where,
        skip,
        take: limit,
        include: {
          user: {
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
}
