import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { PaginationQueryDto } from '../../common/dto/pagination.dto';
import * as argon2 from 'argon2';
import { AuditAction, Prisma } from '@prisma/client';

@Injectable()
export class EmployeesService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateEmployeeDto, creatorUserId?: string) {
    // Check if email or employeeCode or nationalId or phone already exists
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase().trim() },
    });
    if (existingUser) {
      throw new ConflictException('A user with this email already exists');
    }

    const existingCode = await this.prisma.employeeProfile.findUnique({
      where: { employeeCode: dto.employeeCode },
    });
    if (existingCode) {
      throw new ConflictException('An employee with this code already exists');
    }

    const passwordHash = await argon2.hash(dto.password);

    const employee = await this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase().trim(),
        passwordHash,
        role: dto.role,
        employeeProfile: {
          create: {
            employeeCode: dto.employeeCode,
            firstName: dto.firstName,
            lastName: dto.lastName,
            phone: dto.phone,
            nationalId: dto.nationalId,
            jobTitle: dto.jobTitle,
            department: dto.department,
            gender: dto.gender,
            workplaceId: dto.workplaceId,
            scheduleId: dto.scheduleId,
            managerId: dto.managerId,
            baseSalary: dto.baseSalary ? new Prisma.Decimal(dto.baseSalary) : undefined,
          },
        },
      },
      include: {
        employeeProfile: {
          include: {
            workplace: true,
            schedule: true,
          },
        },
      },
    });

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        userId: creatorUserId,
        action: AuditAction.CREATE,
        entity: 'EmployeeProfile',
        entityId: employee.employeeProfile?.id,
        payload: { employeeCode: dto.employeeCode, email: dto.email },
      },
    });

    return employee;
  }

  async findAll(query: PaginationQueryDto) {
    const { skip, limit, search } = query;
    const where: Prisma.EmployeeProfileWhereInput = search
      ? {
          OR: [
            { firstName: { contains: search, mode: 'insensitive' } },
            { lastName: { contains: search, mode: 'insensitive' } },
            { employeeCode: { contains: search, mode: 'insensitive' } },
            { department: { contains: search, mode: 'insensitive' } },
            { jobTitle: { contains: search, mode: 'insensitive' } },
          ],
        }
      : {};

    const [total, data] = await Promise.all([
      this.prisma.employeeProfile.count({ where }),
      this.prisma.employeeProfile.findMany({
        where,
        skip,
        take: limit,
        include: {
          user: { select: { email: true, role: true, status: true } },
          workplace: { select: { id: true, name: true, code: true } },
          schedule: { select: { id: true, name: true } },
        },
        orderBy: { createdAt: 'desc' },
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

  async findOne(id: string) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id },
      include: {
        user: { select: { email: true, role: true, status: true, createdAt: true } },
        workplace: true,
        schedule: true,
        manager: true,
        directReports: true,
      },
    });

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    return employee;
  }

  async update(id: string, dto: UpdateEmployeeDto, updaterUserId?: string) {
    const existing = await this.prisma.employeeProfile.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException('Employee not found');
    }

    const updated = await this.prisma.employeeProfile.update({
      where: { id },
      data: {
        firstName: dto.firstName,
        lastName: dto.lastName,
        phone: dto.phone,
        jobTitle: dto.jobTitle,
        department: dto.department,
        workplaceId: dto.workplaceId,
        scheduleId: dto.scheduleId,
        managerId: dto.managerId,
        gender: dto.gender,
        baseSalary: dto.baseSalary ? new Prisma.Decimal(dto.baseSalary) : undefined,
      },
      include: {
        user: { select: { email: true, role: true, status: true } },
        workplace: true,
        schedule: true,
      },
    });

    if (dto.status || dto.role) {
      await this.prisma.user.update({
        where: { id: existing.userId },
        data: {
          status: dto.status,
          role: dto.role,
        },
      });
    }

    await this.prisma.auditLog.create({
      data: {
        userId: updaterUserId,
        action: AuditAction.UPDATE,
        entity: 'EmployeeProfile',
        entityId: id,
      },
    });

    return updated;
  }

  async remove(id: string, deleterUserId?: string) {
    const existing = await this.prisma.employeeProfile.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException('Employee not found');
    }

    await this.prisma.user.delete({ where: { id: existing.userId } });

    await this.prisma.auditLog.create({
      data: {
        userId: deleterUserId,
        action: AuditAction.DELETE,
        entity: 'EmployeeProfile',
        entityId: id,
      },
    });

    return { message: 'Employee deleted successfully' };
  }
}
