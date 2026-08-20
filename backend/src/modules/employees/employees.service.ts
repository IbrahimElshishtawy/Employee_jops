import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { CompleteProfileDto } from './dto/complete-profile.dto';
import { PaginationQueryDto } from '../../common/dto/pagination.dto';
import * as argon2 from 'argon2';
import { AuditAction, Prisma } from '@prisma/client';
import { AccountState } from '../../common/enums/account-state.enum';

@Injectable()
export class EmployeesService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateEmployeeDto, creatorUserId?: string) {
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

    const passwordHash = dto.password ? await argon2.hash(dto.password) : null;

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
            isProfileComplete: Boolean(dto.firstName && dto.lastName && dto.workplaceId),
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

  /**
   * Complete employee profile onboarding (Employee Self-Service)
   */
  async completeProfile(userId: string, dto: CompleteProfileDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    if (!user) {
      throw new NotFoundException('User account not found');
    }

    // Verify assigned workplace exists
    const workplace = await this.prisma.workplace.findUnique({
      where: { id: dto.workplaceId },
    });
    if (!workplace || !workplace.isActive) {
      throw new BadRequestException('The selected workplace is invalid or inactive');
    }

    // Check unique nationalId conflict if changed
    if (dto.nationalId) {
      const existingNationalId = await this.prisma.employeeProfile.findFirst({
        where: {
          nationalId: dto.nationalId,
          userId: { not: userId },
        },
      });
      if (existingNationalId) {
        throw new ConflictException('This National ID is already registered to another employee');
      }
    }

    // Check phone conflict
    if (dto.phone) {
      const existingPhone = await this.prisma.employeeProfile.findFirst({
        where: {
          phone: dto.phone,
          userId: { not: userId },
        },
      });
      if (existingPhone) {
        throw new ConflictException('This phone number is already registered to another employee');
      }
    }

    // Upsert employee profile
    const profile = await this.prisma.employeeProfile.upsert({
      where: { userId },
      update: {
        firstName: dto.firstName,
        lastName: dto.lastName,
        nationalId: dto.nationalId,
        phone: dto.phone,
        jobTitle: dto.jobTitle,
        department: dto.department,
        workplaceId: dto.workplaceId,
        gender: dto.gender,
        isProfileComplete: true,
        onboardingCompletedAt: new Date(),
      },
      create: {
        userId,
        employeeCode: `CW-${Math.floor(1000 + Math.random() * 9000)}`,
        firstName: dto.firstName,
        lastName: dto.lastName,
        nationalId: dto.nationalId,
        phone: dto.phone,
        jobTitle: dto.jobTitle,
        department: dto.department,
        workplaceId: dto.workplaceId,
        gender: dto.gender,
        isProfileComplete: true,
        onboardingCompletedAt: new Date(),
      },
      include: {
        workplace: true,
        schedule: true,
      },
    });

    // Audit log profile completion (sensitive data omitted from payload)
    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.PROFILE_COMPLETED,
        entity: 'EmployeeProfile',
        entityId: profile.id,
        payload: {
          jobTitle: dto.jobTitle,
          department: dto.department,
          workplaceId: dto.workplaceId,
          isProfileComplete: true,
        },
      },
    });

    return {
      message: 'Profile completed successfully',
      accountState: AccountState.ACTIVE_EMPLOYEE,
      profile: {
        ...profile,
        nationalId: this.maskNationalId(profile.nationalId),
      },
    };
  }

  async getMyProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        role: true,
        status: true,
        employeeProfile: {
          include: {
            workplace: true,
            schedule: true,
          },
        },
      },
    });

    if (!user || !user.employeeProfile) {
      throw new NotFoundException('Employee profile not found');
    }

    const isProfileComplete = user.employeeProfile.isProfileComplete;
    const accountState: AccountState = isProfileComplete
      ? AccountState.ACTIVE_EMPLOYEE
      : AccountState.PROFILE_INCOMPLETE;

    return {
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        status: user.status,
        accountState,
      },
      profile: {
        ...user.employeeProfile,
        nationalId: this.maskNationalId(user.employeeProfile.nationalId),
      },
    };
  }

  async getMyWorkplace(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        employeeProfile: {
          include: { workplace: true },
        },
      },
    });

    if (!user?.employeeProfile?.workplace) {
      throw new NotFoundException('No active workplace assigned to this employee');
    }

    return user.employeeProfile.workplace;
  }

  async getMySchedule(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        employeeProfile: {
          include: { schedule: true },
        },
      },
    });

    if (!user?.employeeProfile?.schedule) {
      throw new NotFoundException('No active work schedule assigned to this employee');
    }

    const schedule = user.employeeProfile.schedule;
    const now = new Date();
    const currentDay = now.getDay(); // 0=Sunday, 1=Monday...
    const isWorkingDay = schedule.workingDays.includes(currentDay);

    return {
      schedule,
      currentServerTime: now.toISOString(),
      isWorkingDayToday: isWorkingDay,
    };
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

    const [total, rawData] = await Promise.all([
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

    // Mask sensitive nationalId
    const data = rawData.map((e) => ({
      ...e,
      nationalId: this.maskNationalId(e.nationalId),
    }));

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

    return {
      ...employee,
      nationalId: this.maskNationalId(employee.nationalId),
    };
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

    return {
      ...updated,
      nationalId: this.maskNationalId(updated.nationalId),
    };
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

  private maskNationalId(nationalId?: string): string | undefined {
    if (!nationalId) return undefined;
    if (nationalId.length <= 4) return '****';
    const last4 = nationalId.slice(-4);
    return `${'*'.repeat(nationalId.length - 4)}${last4}`;
  }
}
