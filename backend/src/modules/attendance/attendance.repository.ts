import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { AttendanceRecord, AttendanceStatus, Prisma } from "@prisma/client";

@Injectable()
export class AttendanceRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findUserWithProfile(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        employeeProfile: {
          include: {
            workplace: true,
            schedule: true,
          },
        },
      },
    });
  }

  async findEmployeeProfile(employeeId: string) {
    return this.prisma.employeeProfile.findUnique({
      where: { id: employeeId },
      include: { workplace: true, user: true, schedule: true },
    });
  }

  async findRecordByRequestId(
    requestId: string,
    tx?: Prisma.TransactionClient,
  ) {
    const client = tx || this.prisma;
    return client.attendanceRecord.findUnique({
      where: { requestId },
    });
  }

  async findRecordByEmployeeAndDate(
    employeeId: string,
    date: Date,
    tx?: Prisma.TransactionClient,
  ) {
    const client = tx || this.prisma;
    return client.attendanceRecord.findUnique({
      where: {
        employeeId_date: {
          employeeId,
          date,
        },
      },
      include: {
        workplace: { select: { id: true, name: true, code: true } },
        events: { orderBy: { timestamp: "desc" } },
      },
    });
  }

  async upsertRecord(
    args: Prisma.AttendanceRecordUpsertArgs,
    tx?: Prisma.TransactionClient,
  ): Promise<AttendanceRecord> {
    const client = tx || this.prisma;
    return client.attendanceRecord.upsert(args);
  }

  async updateRecord(
    args: Prisma.AttendanceRecordUpdateArgs,
    tx?: Prisma.TransactionClient,
  ): Promise<AttendanceRecord> {
    const client = tx || this.prisma;
    return client.attendanceRecord.update(args);
  }

  async createEvent(
    data:
      | Prisma.AttendanceEventCreateInput
      | Prisma.AttendanceEventUncheckedCreateInput,
    tx?: Prisma.TransactionClient,
  ) {
    const client = tx || this.prisma;
    return client.attendanceEvent.create({ data: data as any });
  }

  async createAuditLog(
    data: Prisma.AuditLogCreateInput | Prisma.AuditLogUncheckedCreateInput,
    tx?: Prisma.TransactionClient,
  ) {
    const client = tx || this.prisma;
    return client.auditLog.create({ data: data as any });
  }

  async queryAttendanceRecords(filters: {
    employeeId?: string;
    workplaceId?: string;
    department?: string;
    startDate?: string;
    endDate?: string;
    month?: string;
    status?: AttendanceStatus;
    page?: number;
    limit?: number;
  }) {
    const where: Prisma.AttendanceRecordWhereInput = {};

    if (filters.employeeId) {
      where.employeeId = filters.employeeId;
    }

    if (filters.workplaceId) {
      where.workplaceId = filters.workplaceId;
    }

    if (filters.status) {
      where.status = filters.status;
    }

    if (filters.department) {
      where.employee = { department: filters.department };
    }

    if (filters.month) {
      const [year, month] = filters.month.split("-").map(Number);
      const startOfMonth = new Date(year, month - 1, 1);
      const endOfMonth = new Date(year, month, 0, 23, 59, 59);
      where.date = {
        gte: startOfMonth,
        lte: endOfMonth,
      };
    } else if (filters.startDate && filters.endDate) {
      where.date = {
        gte: new Date(filters.startDate),
        lte: new Date(filters.endDate),
      };
    }

    const page = filters.page || 1;
    const limit = filters.limit || 30;
    const skip = (page - 1) * limit;

    const [total, data] = await Promise.all([
      this.prisma.attendanceRecord.count({ where }),
      this.prisma.attendanceRecord.findMany({
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
            },
          },
          workplace: { select: { id: true, name: true, code: true } },
          events: { orderBy: { timestamp: "desc" } },
        },
        orderBy: { date: "desc" },
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

  async runInTransaction<T>(
    fn: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    return this.prisma.$transaction(fn);
  }
}
