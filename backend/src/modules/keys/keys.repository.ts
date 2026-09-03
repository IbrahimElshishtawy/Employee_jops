import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  CreateKeyDto,
  QueryKeysDto,
  AssignKeyDto,
  LogKeyAccessDto,
} from "./dto";
import { Prisma, KeyAssignmentStatus } from "@prisma/client";

@Injectable()
export class KeysRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createKey(dto: CreateKeyDto) {
    return this.prisma.physicalKey.create({
      data: {
        keyCode: dto.keyCode,
        keyType: dto.keyType,
        name: dto.name,
        location: dto.location,
        totalCopies: dto.totalCopies || 1,
        availableCopies: dto.totalCopies || 1,
        status: dto.status,
      },
    });
  }

  async findKeyById(id: string) {
    return this.prisma.physicalKey.findUnique({
      where: { id },
      include: {
        assignments: {
          where: { status: KeyAssignmentStatus.ACTIVE },
          include: {
            employee: {
              include: { user: { select: { email: true } } },
            },
          },
        },
        accessLogs: {
          take: 10,
          orderBy: { timestamp: "desc" },
        },
      },
    });
  }

  async findKeyByCode(keyCode: string) {
    return this.prisma.physicalKey.findUnique({
      where: { keyCode },
    });
  }

  async findKeys(query: QueryKeysDto) {
    const { page = 1, limit = 20, search, keyType, status } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.PhysicalKeyWhereInput = {};
    if (keyType) where.keyType = keyType;
    if (status) where.status = status;
    if (search) {
      where.OR = [
        { keyCode: { contains: search, mode: "insensitive" } },
        { name: { contains: search, mode: "insensitive" } },
        { location: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.physicalKey.count({ where }),
      this.prisma.physicalKey.findMany({
        where,
        skip,
        take: limit,
        orderBy: { keyCode: "asc" },
        include: {
          assignments: {
            where: { status: KeyAssignmentStatus.ACTIVE },
            include: {
              employee: {
                select: { id: true, firstName: true, lastName: true },
              },
            },
          },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async assignKey(keyId: string, dto: AssignKeyDto) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Decrement available copies
      await tx.physicalKey.update({
        where: { id: keyId },
        data: { availableCopies: { decrement: 1 } },
      });

      // 2. Create assignment
      const assignment = await tx.keyAssignment.create({
        data: {
          keyId,
          employeeId: dto.employeeId,
          expectedReturnAt: dto.expectedReturnAt
            ? new Date(dto.expectedReturnAt)
            : null,
          notes: dto.notes,
          status: KeyAssignmentStatus.ACTIVE,
        },
        include: {
          key: true,
          employee: {
            include: { user: { select: { email: true } } },
          },
        },
      });

      return assignment;
    });
  }

  async findAssignmentById(id: string) {
    return this.prisma.keyAssignment.findUnique({
      where: { id },
      include: { key: true, employee: true },
    });
  }

  async returnKey(assignmentId: string, keyId: string, notes?: string) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Increment available copies
      await tx.physicalKey.update({
        where: { id: keyId },
        data: { availableCopies: { increment: 1 } },
      });

      // 2. Mark assignment returned
      const assignment = await tx.keyAssignment.update({
        where: { id: assignmentId },
        data: {
          status: KeyAssignmentStatus.RETURNED,
          returnedAt: new Date(),
          notes: notes || undefined,
        },
        include: { key: true },
      });

      return assignment;
    });
  }

  async logAccess(keyId: string, dto: LogKeyAccessDto) {
    return this.prisma.keyAccessLog.create({
      data: {
        keyId,
        employeeId: dto.employeeId,
        action: dto.action,
        notes: dto.notes,
      },
      include: {
        key: true,
      },
    });
  }
}
