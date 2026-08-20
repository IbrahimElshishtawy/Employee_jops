import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AdvanceStatus, DeductionType, Prisma, AuditAction } from '@prisma/client';

export interface RequestAdvanceDto {
  amount: number;
  requestedInstallments?: number;
  reason: string;
}

export interface CreateDeductionDto {
  employeeId: string;
  type: DeductionType;
  amount: number;
  reason: string;
  effectiveDate: string;
}

@Injectable()
export class PayrollService {
  constructor(private prisma: PrismaService) {}

  async requestAdvance(userId: string, dto: RequestAdvanceDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    if (!user?.employeeProfile) {
      throw new BadRequestException('Employee profile required');
    }

    return this.prisma.financialAdvance.create({
      data: {
        employeeId: user.employeeProfile.id,
        amount: new Prisma.Decimal(dto.amount),
        requestedInstallments: dto.requestedInstallments || 1,
        reason: dto.reason,
        status: AdvanceStatus.PENDING,
      },
    });
  }

  async getMyAdvances(employeeProfileId: string) {
    return this.prisma.financialAdvance.findMany({
      where: { employeeId: employeeProfileId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAllAdvances(status?: AdvanceStatus) {
    return this.prisma.financialAdvance.findMany({
      where: status ? { status } : {},
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
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateAdvanceStatus(
    id: string,
    status: AdvanceStatus,
    approvedAmount?: number,
    remarks?: string,
    approverId?: string,
  ) {
    const advance = await this.prisma.financialAdvance.findUnique({ where: { id } });
    if (!advance) {
      throw new NotFoundException('Advance request not found');
    }

    return this.prisma.financialAdvance.update({
      where: { id },
      data: {
        status,
        approvedAmount: approvedAmount ? new Prisma.Decimal(approvedAmount) : advance.amount,
        remarks,
        approvedById: approverId,
        approvedAt: new Date(),
      },
    });
  }

  async createDeduction(dto: CreateDeductionDto, createdById?: string) {
    return this.prisma.financialDeduction.create({
      data: {
        employeeId: dto.employeeId,
        type: dto.type,
        amount: new Prisma.Decimal(dto.amount),
        reason: dto.reason,
        effectiveDate: new Date(dto.effectiveDate),
        createdById,
      },
    });
  }

  async getMyDeductions(employeeProfileId: string) {
    return this.prisma.financialDeduction.findMany({
      where: { employeeId: employeeProfileId },
      orderBy: { effectiveDate: 'desc' },
    });
  }

  async getAllDeductions(employeeId?: string) {
    return this.prisma.financialDeduction.findMany({
      where: employeeId ? { employeeId } : {},
      include: {
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            department: true,
          },
        },
      },
      orderBy: { effectiveDate: 'desc' },
    });
  }
}
