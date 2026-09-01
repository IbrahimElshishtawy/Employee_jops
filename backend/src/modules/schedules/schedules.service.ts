import { Injectable, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateScheduleDto, UpdateScheduleDto } from "./dto";

@Injectable()
export class SchedulesService {
  constructor(private prisma: PrismaService) {}

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

  async findOne(id: string) {
    const schedule = await this.prisma.schedule.findUnique({
      where: { id },
      include: { workplace: true, employees: true },
    });

    if (!schedule) {
      throw new NotFoundException("Schedule not found");
    }

    return schedule;
  }

  async update(id: string, data: UpdateScheduleDto) {
    await this.findOne(id);
    return this.prisma.schedule.update({
      where: { id },
      data,
    });
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.prisma.schedule.delete({ where: { id } });
  }
}

