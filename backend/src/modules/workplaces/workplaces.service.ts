import {
  Injectable,
  NotFoundException,
  ConflictException,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateWorkplaceDto } from "./dto/create-workplace.dto";
import { UpdateWorkplaceDto } from "./dto/update-workplace.dto";

@Injectable()
export class WorkplacesService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateWorkplaceDto) {
    const existing = await this.prisma.workplace.findUnique({
      where: { code: dto.code },
    });
    if (existing) {
      throw new ConflictException("Workplace code already exists");
    }

    return this.prisma.workplace.create({ data: dto });
  }

  async findAll() {
    return this.prisma.workplace.findMany({
      include: {
        _count: { select: { employees: true } },
      },
      orderBy: { name: "asc" },
    });
  }

  async findOne(id: string) {
    const workplace = await this.prisma.workplace.findUnique({
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
      },
    });

    if (!workplace) {
      throw new NotFoundException("Workplace not found");
    }

    return workplace;
  }

  async update(id: string, dto: UpdateWorkplaceDto) {
    await this.findOne(id);
    return this.prisma.workplace.update({
      where: { id },
      data: dto,
    });
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.prisma.workplace.delete({ where: { id } });
  }
}
