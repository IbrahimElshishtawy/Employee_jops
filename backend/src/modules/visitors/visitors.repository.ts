import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CheckInVisitorDto, CheckOutVisitorDto, QueryVisitorsDto } from "./dto";
import { Prisma, VisitorStatus } from "@prisma/client";

@Injectable()
export class VisitorsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async generateVisitorNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.visitorLog.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `VIS-${today}-${seq}`;
  }

  async checkInVisitor(dto: CheckInVisitorDto, visitorNumber: string) {
    return this.prisma.visitorLog.create({
      data: {
        visitorNumber,
        fullName: dto.fullName,
        phone: dto.phone,
        company: dto.company,
        nationalIdOrPassport: dto.nationalIdOrPassport,
        purpose: dto.purpose,
        hostEmployeeId: dto.hostEmployeeId,
        badgeNumber: dto.badgeNumber,
        checkInTime: new Date(),
        status: VisitorStatus.CHECKED_IN,
        remarks: dto.remarks,
      },
      include: {
        hostEmployee: {
          include: { user: { select: { email: true } } },
        },
      },
    });
  }

  async checkOutVisitor(id: string, dto: CheckOutVisitorDto) {
    return this.prisma.visitorLog.update({
      where: { id },
      data: {
        checkOutTime: new Date(),
        status: VisitorStatus.CHECKED_OUT,
        remarks: dto.remarks ? dto.remarks : undefined,
      },
      include: { hostEmployee: true },
    });
  }

  async findVisitorById(id: string) {
    return this.prisma.visitorLog.findUnique({
      where: { id },
      include: {
        hostEmployee: {
          include: { user: { select: { email: true } } },
        },
      },
    });
  }

  async findVisitors(query: QueryVisitorsDto) {
    const { page = 1, limit = 20, search, status, hostEmployeeId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.VisitorLogWhereInput = {};
    if (status) where.status = status;
    if (hostEmployeeId) where.hostEmployeeId = hostEmployeeId;
    if (search) {
      where.OR = [
        { fullName: { contains: search, mode: "insensitive" } },
        { phone: { contains: search, mode: "insensitive" } },
        { company: { contains: search, mode: "insensitive" } },
        { visitorNumber: { contains: search, mode: "insensitive" } },
        { badgeNumber: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.visitorLog.count({ where }),
      this.prisma.visitorLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { checkInTime: "desc" },
        include: {
          hostEmployee: {
            select: { id: true, firstName: true, lastName: true },
          },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }
}
