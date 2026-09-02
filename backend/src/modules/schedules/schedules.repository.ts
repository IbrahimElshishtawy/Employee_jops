import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateScheduleDto, UpdateScheduleDto } from "./dto";

@Injectable()
export class SchedulesRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: CreateScheduleDto) {
    return this.prisma.schedule.create({ data });
  }

  async findAll() {
    return this.prisma.schedule.findMany({
      include: {
        workplace: { select: { id: true, name: true } },
        _count: { select: { employees: true } },
      },
    });
  }

  async findById(id: string) {
    return this.prisma.schedule.findUnique({
      where: { id },
      include: { workplace: true, employees: true },
    });
  }

  async update(id: string, data: UpdateScheduleDto) {
    return this.prisma.schedule.update({
      where: { id },
      data,
    });
  }

  async delete(id: string) {
    return this.prisma.schedule.delete({ where: { id } });
  }

  async assignToEmployee(scheduleId: string, employeeId: string) {
    return this.prisma.employeeProfile.update({
      where: { id: employeeId },
      data: { scheduleId },
    });
  }
}
