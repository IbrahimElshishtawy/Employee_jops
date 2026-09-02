import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateWorkplaceDto } from "./dto/create-workplace.dto";
import { UpdateWorkplaceDto } from "./dto/update-workplace.dto";

@Injectable()
export class WorkplacesRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findByCode(code: string) {
    return this.prisma.workplace.findUnique({
      where: { code },
    });
  }

  async findById(id: string) {
    return this.prisma.workplace.findUnique({
      where: { id },
      include: {
        employees: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
          },
        },
        schedules: true,
        branch: { select: { id: true, name: true, code: true } },
        organization: { select: { id: true, name: true } },
      },
    });
  }

  async findAll() {
    return this.prisma.workplace.findMany({
      include: {
        _count: { select: { employees: true } },
        branch: { select: { id: true, name: true } },
      },
      orderBy: { name: "asc" },
    });
  }

  async create(dto: CreateWorkplaceDto) {
    return this.prisma.workplace.create({ data: dto });
  }

  async update(id: string, dto: UpdateWorkplaceDto) {
    return this.prisma.workplace.update({
      where: { id },
      data: dto,
    });
  }

  async delete(id: string) {
    return this.prisma.workplace.delete({ where: { id } });
  }

  async assignToEmployee(workplaceId: string, employeeId: string) {
    return this.prisma.employeeProfile.update({
      where: { id: employeeId },
      data: { workplaceId },
    });
  }
}
