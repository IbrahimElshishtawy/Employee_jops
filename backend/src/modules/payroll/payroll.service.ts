import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PayrollCalculatorService } from './payroll-calculator.service';
import {
  CreateSalaryProfileDto,
  RequestAdvanceDto,
  ApproveAdvanceDto,
  RejectAdvanceDto,
  PayInstallmentDto,
  QueryAdvancesDto,
  CreateDeductionDto,
  QueryDeductionsDto,
  CreatePayrollPeriodDto,
  CalculatePayrollDto,
  FinalizePayrollDto,
  CreateAdjustmentDto,
  QueryPayrollDto,
} from './dto';
import {
  AdvanceStatus,
  InstallmentStatus,
  PayrollPeriodStatus,
  PayrollRecordStatus,
  PayrollLineItemType,
  AuditAction,
  NotificationType,
  UserStatus,
  Role,
  Prisma,
} from '@prisma/client';

@Injectable()
export class PayrollService {
  private readonly logger = new Logger(PayrollService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly payrollCalculator: PayrollCalculatorService,
  ) {}

  // ============================================================
  // 1. SALARY PROFILE & HISTORY
  // ============================================================

  async getSalaryProfile(employeeId: string, currentUser: { id: string; role: Role; employeeProfileId?: string }) {
    const isHr = ([Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER] as Role[]).includes(currentUser.role);
    const isOwner = currentUser.employeeProfileId === employeeId;

    if (!isHr && !isOwner) {
      throw new ForbiddenException('You do not have permission to view this salary profile');
    }

    const profile = await this.prisma.salaryProfile.findUnique({
      where: { employeeId },
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
    });

    if (!profile) {
      // Return default profile representation if not initialized
      const emp = await this.prisma.employeeProfile.findUnique({ where: { id: employeeId } });
      if (!emp) throw new NotFoundException('Employee not found');
      return {
        employeeId,
        basicSalary: emp.baseSalary || new Prisma.Decimal(10000),
        allowances: new Prisma.Decimal(0),
        currency: 'EGP',
        status: UserStatus.ACTIVE,
        effectiveFrom: new Date(),
        employee: emp,
      };
    }

    return profile;
  }

  async setSalaryProfile(dto: CreateSalaryProfileDto, currentUserId: string) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.employeeId },
    });

    if (!employee) {
      throw new NotFoundException('Employee not found');
    }

    const existingProfile = await this.prisma.salaryProfile.findUnique({
      where: { employeeId: dto.employeeId },
    });

    const basicSalaryDecimal = new Prisma.Decimal(dto.basicSalary);
    const allowancesDecimal = new Prisma.Decimal(dto.allowances || 0);
    const effectiveDate = dto.effectiveFrom ? new Date(dto.effectiveFrom) : new Date();

    const result = await this.prisma.$transaction(async (tx) => {
      let profile;
      if (existingProfile) {
        profile = await tx.salaryProfile.update({
          where: { employeeId: dto.employeeId },
          data: {
            basicSalary: basicSalaryDecimal,
            allowances: allowancesDecimal,
            currency: dto.currency || 'EGP',
            effectiveFrom: effectiveDate,
          },
        });

        // Record Salary History
        await tx.salaryHistory.create({
          data: {
            employeeId: dto.employeeId,
            oldBasicSalary: existingProfile.basicSalary,
            newBasicSalary: basicSalaryDecimal,
            oldAllowances: existingProfile.allowances,
            newAllowances: allowancesDecimal,
            effectiveDate,
            changedById: currentUserId,
            reason: dto.reason,
          },
        });

        await tx.auditLog.create({
          data: {
            userId: currentUserId,
            action: AuditAction.SALARY_CHANGED,
            entity: 'SalaryProfile',
            entityId: profile.id,
            payload: {
              previousBasic: existingProfile.basicSalary,
              newBasic: basicSalaryDecimal,
              reason: dto.reason,
            },
          },
        });
      } else {
        profile = await tx.salaryProfile.create({
          data: {
            employeeId: dto.employeeId,
            basicSalary: basicSalaryDecimal,
            allowances: allowancesDecimal,
            currency: dto.currency || 'EGP',
            effectiveFrom: effectiveDate,
            status: UserStatus.ACTIVE,
          },
        });

        await tx.salaryHistory.create({
          data: {
            employeeId: dto.employeeId,
            oldBasicSalary: new Prisma.Decimal(0),
            newBasicSalary: basicSalaryDecimal,
            oldAllowances: new Prisma.Decimal(0),
            newAllowances: allowancesDecimal,
            effectiveDate,
            changedById: currentUserId,
            reason: dto.reason || 'Initial salary profile creation',
          },
        });

        await tx.auditLog.create({
          data: {
            userId: currentUserId,
            action: AuditAction.SALARY_CREATED,
            entity: 'SalaryProfile',
            entityId: profile.id,
            payload: { basicSalary: basicSalaryDecimal, reason: dto.reason },
          },
        });
      }

      // Sync baseSalary field on employeeProfile
      await tx.employeeProfile.update({
        where: { id: dto.employeeId },
        data: { baseSalary: basicSalaryDecimal },
      });

      return profile;
    });

    return result;
  }

  async getSalaryHistory(employeeId: string) {
    return this.prisma.salaryHistory.findMany({
      where: { employeeId },
      orderBy: { createdAt: 'desc' },
    });
  }

  // ============================================================
  // 2. SALARY ADVANCES & INSTALLMENTS
  // ============================================================

  async requestAdvance(userId: string, dto: RequestAdvanceDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    if (!user?.employeeProfile) {
      throw new BadRequestException('Employee profile required to request salary advance');
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException('Inactive or suspended employees cannot request salary advances');
    }

    const employeeId = user.employeeProfile.id;

    // 1. Idempotency Check
    if (dto.idempotencyKey) {
      const existing = await this.prisma.financialAdvance.findUnique({
        where: { idempotencyKey: dto.idempotencyKey },
        include: { installments: true },
      });
      if (existing) {
        if (existing.employeeId !== employeeId) {
          throw new ForbiddenException('Idempotency key collision');
        }
        return existing;
      }
    }

    // 2. Amount and Eligibility Checks
    const advanceAmount = new Prisma.Decimal(dto.amount);
    if (advanceAmount.lessThanOrEqualTo(0)) {
      throw new BadRequestException('Advance amount must be strictly greater than 0');
    }

    const salaryProfile = await this.prisma.salaryProfile.findUnique({
      where: { employeeId },
    });
    const monthlySalary = salaryProfile?.basicSalary || user.employeeProfile.baseSalary || new Prisma.Decimal(10000);

    // Limit check: Maximum single advance cannot exceed 3x monthly basic salary
    const maxAllowedLimit = monthlySalary.times(3);
    if (advanceAmount.greaterThan(maxAllowedLimit)) {
      throw new BadRequestException(
        `Requested advance (${advanceAmount}) exceeds allowable maximum limit (${maxAllowedLimit})`,
      );
    }

    // Check for existing pending advance
    const pendingAdvance = await this.prisma.financialAdvance.findFirst({
      where: {
        employeeId,
        status: AdvanceStatus.PENDING,
      },
    });

    if (pendingAdvance) {
      throw new BadRequestException('You already have a pending advance request awaiting review');
    }

    // 3. Create Advance Record
    const advance = await this.prisma.financialAdvance.create({
      data: {
        idempotencyKey: dto.idempotencyKey,
        employeeId,
        amount: advanceAmount,
        remainingAmount: advanceAmount,
        paidAmount: new Prisma.Decimal(0),
        requestedInstallments: dto.requestedInstallments || 1,
        reason: dto.reason,
        status: AdvanceStatus.PENDING,
      },
    });

    // 4. Audit Log
    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.ADVANCE_CREATED,
        entity: 'FinancialAdvance',
        entityId: advance.id,
        payload: {
          amount: dto.amount,
          installments: dto.requestedInstallments,
          reason: dto.reason,
        },
      },
    });

    return advance;
  }

  async getMyAdvances(employeeProfileId: string, query: Partial<QueryAdvancesDto> = {}) {
    const { page = 1, limit = 10, status } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.FinancialAdvanceWhereInput = {
      employeeId: employeeProfileId,
    };
    if (status) where.status = status;

    const [total, data] = await Promise.all([
      this.prisma.financialAdvance.count({ where }),
      this.prisma.financialAdvance.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          installments: {
            orderBy: { installmentNumber: 'asc' },
          },
        },
      }),
    ]);

    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async getAllAdvances(query: Partial<QueryAdvancesDto> = {}) {
    const { page = 1, limit = 10, status, employeeId, department } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.FinancialAdvanceWhereInput = {};
    if (status) where.status = status;
    if (employeeId) where.employeeId = employeeId;
    if (department) {
      where.employee = { department };
    }

    const [total, data] = await Promise.all([
      this.prisma.financialAdvance.count({ where }),
      this.prisma.financialAdvance.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
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
          installments: {
            orderBy: { installmentNumber: 'asc' },
          },
        },
      }),
    ]);

    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async getAdvanceDetails(id: string, currentUser: { id: string; role: Role; employeeProfileId?: string }) {
    const advance = await this.prisma.financialAdvance.findUnique({
      where: { id },
      include: {
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            department: true,
            user: { select: { id: true, email: true } },
          },
        },
        installments: {
          orderBy: { installmentNumber: 'asc' },
        },
      },
    });

    if (!advance) throw new NotFoundException('Advance request not found');

    const isHr = ([Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER] as Role[]).includes(currentUser.role);
    const isOwner = currentUser.employeeProfileId === advance.employeeId;

    if (!isHr && !isOwner) {
      throw new ForbiddenException('You do not have permission to view this advance request');
    }

    return advance;
  }

  async approveAdvance(id: string, approverUserId: string, dto?: ApproveAdvanceDto) {
    const advance = await this.prisma.financialAdvance.findUnique({
      where: { id },
      include: { employee: { include: { user: true } } },
    });

    if (!advance) throw new NotFoundException('Advance request not found');

    if (advance.status === AdvanceStatus.APPROVED || advance.status === AdvanceStatus.ACTIVE) {
      throw new BadRequestException('Advance is already approved');
    }

    if (advance.status !== AdvanceStatus.PENDING) {
      throw new BadRequestException(`Cannot approve advance in ${advance.status} status`);
    }

    const approvedAmount = dto?.approvedAmount
      ? new Prisma.Decimal(dto.approvedAmount)
      : advance.amount;
    const installmentsCount = dto?.installmentsCount || advance.requestedInstallments || 1;

    // Calculate installment amount
    const installmentAmount = approvedAmount.dividedBy(installmentsCount).toDecimalPlaces(2);
    let firstDueDate = dto?.firstDueDate ? new Date(dto.firstDueDate) : new Date();
    // Move to 1st of next month by default
    firstDueDate = new Date(Date.UTC(firstDueDate.getUTCFullYear(), firstDueDate.getUTCMonth() + 1, 1));

    const updated = await this.prisma.$transaction(async (tx) => {
      // 1. Update advance
      const updatedAdv = await tx.financialAdvance.update({
        where: { id },
        data: {
          status: AdvanceStatus.ACTIVE,
          approvedAmount,
          remainingAmount: approvedAmount,
          paidAmount: new Prisma.Decimal(0),
          requestedInstallments: installmentsCount,
          remarks: dto?.remarks || 'Approved by HR',
          approvedById: approverUserId,
          approvedAt: new Date(),
        },
      });

      // 2. Generate Installment Schedule
      let remainingToAllocate = approvedAmount;
      for (let i = 1; i <= installmentsCount; i++) {
        const dueDate = new Date(firstDueDate.getTime());
        dueDate.setUTCMonth(dueDate.getUTCMonth() + (i - 1));

        // Adjust last installment for any remainder cents
        let amount = installmentAmount;
        if (i === installmentsCount) {
          amount = remainingToAllocate;
        } else {
          remainingToAllocate = remainingToAllocate.minus(amount);
        }

        await tx.advanceInstallment.create({
          data: {
            advanceId: id,
            installmentNumber: i,
            amount,
            paidAmount: new Prisma.Decimal(0),
            remainingAmount: amount,
            dueDate,
            status: InstallmentStatus.PENDING,
          },
        });
      }

      // 3. Audit Log
      await tx.auditLog.create({
        data: {
          userId: approverUserId,
          action: AuditAction.ADVANCE_APPROVED,
          entity: 'FinancialAdvance',
          entityId: id,
          payload: {
            approvedAmount,
            installmentsCount,
            remarks: dto?.remarks,
          },
        },
      });

      return updatedAdv;
    });

    // 4. Notification
    try {
      if (advance.employee?.user?.id) {
        await this.notificationsService.sendNotification(
          advance.employee.user.id,
          'Salary Advance Approved',
          `Your advance request for ${approvedAmount} has been approved with ${installmentsCount} installments.`,
          NotificationType.ADVANCE_STATUS_UPDATE,
          { advanceId: id, status: AdvanceStatus.ACTIVE },
        );
      }
    } catch (notifErr: any) {
      this.logger.warn(`Failed to dispatch advance approval notification: ${notifErr?.message || notifErr}`);
    }

    return updated;
  }

  async rejectAdvance(id: string, approverUserId: string, dto: RejectAdvanceDto) {
    if (!dto?.reason || dto.reason.trim().length === 0) {
      throw new BadRequestException('Rejection reason is required');
    }

    const advance = await this.prisma.financialAdvance.findUnique({
      where: { id },
      include: { employee: { include: { user: true } } },
    });

    if (!advance) throw new NotFoundException('Advance request not found');

    if (advance.status === AdvanceStatus.REJECTED) {
      throw new BadRequestException('Advance is already rejected');
    }

    if (advance.status !== AdvanceStatus.PENDING) {
      throw new BadRequestException(`Cannot reject advance in ${advance.status} status`);
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const updatedAdv = await tx.financialAdvance.update({
        where: { id },
        data: {
          status: AdvanceStatus.REJECTED,
          rejectionReason: dto.reason,
          approvedById: approverUserId,
          approvedAt: new Date(),
        },
      });

      await tx.auditLog.create({
        data: {
          userId: approverUserId,
          action: AuditAction.ADVANCE_REJECTED,
          entity: 'FinancialAdvance',
          entityId: id,
          payload: { reason: dto.reason },
        },
      });

      return updatedAdv;
    });

    try {
      if (advance.employee?.user?.id) {
        await this.notificationsService.sendNotification(
          advance.employee.user.id,
          'Salary Advance Rejected',
          `Your advance request was rejected: ${dto.reason}`,
          NotificationType.ADVANCE_STATUS_UPDATE,
          { advanceId: id, status: AdvanceStatus.REJECTED, reason: dto.reason },
        );
      }
    } catch (notifErr: any) {
      this.logger.warn(`Failed to dispatch advance rejection notification: ${notifErr?.message || notifErr}`);
    }

    return updated;
  }

  async recordInstallmentPayment(installmentId: string, currentUserId: string, dto: PayInstallmentDto) {
    const installment = await this.prisma.advanceInstallment.findUnique({
      where: { id: installmentId },
      include: {
        advance: {
          include: { employee: { include: { user: true } } },
        },
      },
    });

    if (!installment) throw new NotFoundException('Installment not found');

    if (installment.status === InstallmentStatus.PAID) {
      throw new BadRequestException('Installment is already fully paid');
    }

    const paymentAmount = new Prisma.Decimal(dto.amount);
    if (paymentAmount.lessThanOrEqualTo(0)) {
      throw new BadRequestException('Payment amount must be greater than 0');
    }

    if (paymentAmount.greaterThan(installment.remainingAmount)) {
      throw new BadRequestException(
        `Payment amount (${paymentAmount}) exceeds remaining installment balance (${installment.remainingAmount})`,
      );
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const newPaidAmount = new Prisma.Decimal(installment.paidAmount).plus(paymentAmount);
      const newRemainingAmount = new Prisma.Decimal(installment.remainingAmount).minus(paymentAmount);
      const isFullyPaid = newRemainingAmount.isZero() || newRemainingAmount.lessThan(0.01);

      // 1. Update Installment
      const updatedInst = await tx.advanceInstallment.update({
        where: { id: installmentId },
        data: {
          paidAmount: newPaidAmount,
          remainingAmount: isFullyPaid ? new Prisma.Decimal(0) : newRemainingAmount,
          status: isFullyPaid ? InstallmentStatus.PAID : InstallmentStatus.PARTIALLY_PAID,
          paidAt: isFullyPaid ? new Date() : installment.paidAt,
          notes: dto.notes,
        },
      });

      // 2. Update Parent Advance
      const parentAdv = installment.advance;
      const advPaidAmount = new Prisma.Decimal(parentAdv.paidAmount).plus(paymentAmount);
      const advRemainingAmount = new Prisma.Decimal(parentAdv.remainingAmount).minus(paymentAmount);
      const isAdvFullyPaid = advRemainingAmount.isZero() || advRemainingAmount.lessThan(0.01);

      await tx.financialAdvance.update({
        where: { id: parentAdv.id },
        data: {
          paidAmount: advPaidAmount,
          remainingAmount: isAdvFullyPaid ? new Prisma.Decimal(0) : advRemainingAmount,
          status: isAdvFullyPaid ? AdvanceStatus.PAID : AdvanceStatus.PARTIALLY_PAID,
        },
      });

      // 3. Audit Log
      await tx.auditLog.create({
        data: {
          userId: currentUserId,
          action: AuditAction.ADVANCE_PAYMENT_RECORDED,
          entity: 'AdvanceInstallment',
          entityId: installmentId,
          payload: {
            advanceId: parentAdv.id,
            paymentAmount,
            remainingInstallment: newRemainingAmount,
            remainingAdvance: advRemainingAmount,
          },
        },
      });

      return updatedInst;
    });

    // 4. Notification
    try {
      if (installment.advance?.employee?.user?.id) {
        await this.notificationsService.sendNotification(
          installment.advance.employee.user.id,
          'Advance Payment Recorded',
          `Payment of ${paymentAmount} recorded for installment #${installment.installmentNumber}.`,
          NotificationType.ADVANCE_STATUS_UPDATE,
          { installmentId, amount: paymentAmount },
        );
      }
    } catch (notifErr: any) {
      this.logger.warn(`Failed to dispatch payment notification: ${notifErr?.message || notifErr}`);
    }

    return updated;
  }

  // ============================================================
  // 3. MANUAL DEDUCTIONS
  // ============================================================

  async createDeduction(dto: CreateDeductionDto, createdById: string) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.employeeId },
      include: { user: true },
    });

    if (!employee) throw new NotFoundException('Employee not found');

    const amountDecimal = new Prisma.Decimal(dto.amount);
    if (amountDecimal.lessThanOrEqualTo(0)) {
      throw new BadRequestException('Deduction amount must be greater than 0');
    }

    const deduction = await this.prisma.financialDeduction.create({
      data: {
        employeeId: dto.employeeId,
        type: dto.type,
        amount: amountDecimal,
        reason: dto.reason,
        effectiveDate: new Date(dto.effectiveDate),
        createdById,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: createdById,
        action: AuditAction.DEDUCTION_CREATED,
        entity: 'FinancialDeduction',
        entityId: deduction.id,
        payload: { ...dto },
      },
    });

    try {
      if (employee.user?.id) {
        await this.notificationsService.sendNotification(
          employee.user.id,
          'Financial Deduction Notice',
          `A deduction of ${amountDecimal} (${dto.type}) was applied: ${dto.reason}`,
          NotificationType.DEDUCTION_ALERT,
          { deductionId: deduction.id, amount: amountDecimal },
        );
      }
    } catch (notifErr: any) {
      this.logger.warn(`Failed to dispatch deduction notification: ${notifErr?.message || notifErr}`);
    }

    return deduction;
  }

  async getMyDeductions(employeeProfileId: string, query: Partial<QueryDeductionsDto> = {}) {
    const { page = 1, limit = 10, type, startDate, endDate } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.FinancialDeductionWhereInput = {
      employeeId: employeeProfileId,
    };
    if (type) where.type = type;
    if (startDate || endDate) {
      where.effectiveDate = {};
      if (startDate) where.effectiveDate.gte = new Date(startDate);
      if (endDate) where.effectiveDate.lte = new Date(endDate);
    }

    const [total, data] = await Promise.all([
      this.prisma.financialDeduction.count({ where }),
      this.prisma.financialDeduction.findMany({
        where,
        skip,
        take: limit,
        orderBy: { effectiveDate: 'desc' },
      }),
    ]);

    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async getAllDeductions(query: Partial<QueryDeductionsDto> = {}) {
    const { page = 1, limit = 10, employeeId, type, startDate, endDate } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.FinancialDeductionWhereInput = {};
    if (employeeId) where.employeeId = employeeId;
    if (type) where.type = type;
    if (startDate || endDate) {
      where.effectiveDate = {};
      if (startDate) where.effectiveDate.gte = new Date(startDate);
      if (endDate) where.effectiveDate.lte = new Date(endDate);
    }

    const [total, data] = await Promise.all([
      this.prisma.financialDeduction.count({ where }),
      this.prisma.financialDeduction.findMany({
        where,
        skip,
        take: limit,
        orderBy: { effectiveDate: 'desc' },
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
      }),
    ]);

    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  // ============================================================
  // 4. PAYROLL PERIODS & CALCULATION ENGINE
  // ============================================================

  async createPayrollPeriod(dto: CreatePayrollPeriodDto, currentUserId: string) {
    const existing = await this.prisma.payrollPeriod.findUnique({
      where: { name: dto.name },
    });

    if (existing) {
      throw new BadRequestException(`Payroll period ${dto.name} already exists`);
    }

    const startDate = new Date(dto.startDate);
    const endDate = new Date(dto.endDate);
    if (startDate > endDate) {
      throw new BadRequestException('Start date must be before or equal to end date');
    }

    const period = await this.prisma.payrollPeriod.create({
      data: {
        name: dto.name,
        startDate,
        endDate,
        status: PayrollPeriodStatus.OPEN,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: currentUserId,
        action: AuditAction.CREATE,
        entity: 'PayrollPeriod',
        entityId: period.id,
        payload: { ...dto },
      },
    });

    return period;
  }

  async getPayrollPeriods(page = 1, limit = 12) {
    const skip = (page - 1) * limit;
    const [total, data] = await Promise.all([
      this.prisma.payrollPeriod.count(),
      this.prisma.payrollPeriod.findMany({
        skip,
        take: limit,
        orderBy: { startDate: 'desc' },
      }),
    ]);

    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async calculatePeriodPayroll(periodId: string, dto: CalculatePayrollDto, currentUserId: string) {
    const period = await this.prisma.payrollPeriod.findUnique({
      where: { id: periodId },
    });

    if (!period) throw new NotFoundException('Payroll period not found');

    if (period.status === PayrollPeriodStatus.FINALIZED || period.status === PayrollPeriodStatus.LOCKED) {
      throw new BadRequestException(`Cannot calculate finalized or locked payroll period (${period.status})`);
    }

    // Determine target employees
    const employeeWhere: Prisma.EmployeeProfileWhereInput = {
      user: { status: UserStatus.ACTIVE },
    };
    if (dto.employeeId) employeeWhere.id = dto.employeeId;
    if (dto.department) employeeWhere.department = dto.department;

    const employees = await this.prisma.employeeProfile.findMany({
      where: employeeWhere,
      select: { id: true },
    });

    if (employees.length === 0) {
      throw new BadRequestException('No active employees match the calculation criteria');
    }

    const results: any[] = [];

    await this.prisma.$transaction(async (tx) => {
      // Set period status to CALCULATING
      await tx.payrollPeriod.update({
        where: { id: periodId },
        data: { status: PayrollPeriodStatus.CALCULATING },
      });

      for (const emp of employees) {
        const calc = await this.payrollCalculator.calculateEmployeePayroll(
          emp.id,
          period.startDate,
          period.endDate,
          tx,
        );

        // Delete existing draft/calculated record and its line items if recalculating
        const existingRecord = await tx.payrollRecord.findUnique({
          where: {
            employeeId_payrollPeriodId: {
              employeeId: emp.id,
              payrollPeriodId: periodId,
            },
          },
        });

        if (existingRecord) {
          await tx.payrollLineItem.deleteMany({ where: { payrollRecordId: existingRecord.id } });
          await tx.payrollRecord.delete({ where: { id: existingRecord.id } });
        }

        // Create Payroll Record
        const record = await tx.payrollRecord.create({
          data: {
            employeeId: emp.id,
            payrollPeriodId: periodId,
            basicSalary: calc.basicSalary,
            allowances: calc.allowances,
            grossSalary: calc.grossSalary,
            totalDeductions: calc.totalDeductions,
            netSalary: calc.netSalary,
            status: PayrollRecordStatus.CALCULATED,
            calculatedAt: new Date(),
          },
        });

        // Insert Line Items
        for (const item of calc.lineItems) {
          await tx.payrollLineItem.create({
            data: {
              payrollRecordId: record.id,
              type: item.type,
              name: item.name,
              description: item.description,
              amount: item.amount,
              isDeduction: item.isDeduction,
              source: item.source,
              sourceId: item.sourceId,
            },
          });
        }

        results.push(record);
      }

      // Update period status to REVIEW
      await tx.payrollPeriod.update({
        where: { id: periodId },
        data: { status: PayrollPeriodStatus.REVIEW },
      });

      await tx.auditLog.create({
        data: {
          userId: currentUserId,
          action: AuditAction.PAYROLL_CALCULATED,
          entity: 'PayrollPeriod',
          entityId: periodId,
          payload: {
            calculatedEmployeesCount: employees.length,
            period: period.name,
          },
        },
      });
    });

    return {
      message: `Successfully calculated payroll for ${results.length} employee(s)`,
      periodId,
      periodName: period.name,
      recordsCount: results.length,
    };
  }

  async finalizePayrollPeriod(periodId: string, currentUserId: string, dto?: FinalizePayrollDto) {
    const period = await this.prisma.payrollPeriod.findUnique({
      where: { id: periodId },
      include: { payrollRecords: { include: { lineItems: true } } },
    });

    if (!period) throw new NotFoundException('Payroll period not found');

    if (period.status === PayrollPeriodStatus.FINALIZED || period.status === PayrollPeriodStatus.LOCKED) {
      throw new BadRequestException('Payroll period is already finalized');
    }

    if (period.payrollRecords.length === 0) {
      throw new BadRequestException('Cannot finalize an empty payroll period. Run calculation first.');
    }

    await this.prisma.$transaction(async (tx) => {
      // 1. Lock period
      await tx.payrollPeriod.update({
        where: { id: periodId },
        data: {
          status: PayrollPeriodStatus.FINALIZED,
          finalizedById: currentUserId,
          finalizedAt: new Date(),
        },
      });

      // 2. Lock all payroll records
      await tx.payrollRecord.updateMany({
        where: { payrollPeriodId: periodId },
        data: {
          status: PayrollRecordStatus.FINALIZED,
          finalizedAt: new Date(),
        },
      });

      // 3. Mark deducted advance installments as PAID and update parent advances
      for (const rec of period.payrollRecords) {
        for (const item of rec.lineItems) {
          if (item.type === PayrollLineItemType.ADVANCE_INSTALLMENT && item.sourceId) {
            const installment = await tx.advanceInstallment.findUnique({
              where: { id: item.sourceId },
              include: { advance: true },
            });

            if (installment && installment.status !== InstallmentStatus.PAID) {
              await tx.advanceInstallment.update({
                where: { id: installment.id },
                data: {
                  paidAmount: installment.amount,
                  remainingAmount: new Prisma.Decimal(0),
                  status: InstallmentStatus.PAID,
                  paidAt: new Date(),
                  payrollPeriodId: periodId,
                },
              });

              const adv = installment.advance;
              const newAdvPaid = new Prisma.Decimal(adv.paidAmount).plus(item.amount);
              const newAdvRemaining = new Prisma.Decimal(adv.remainingAmount).minus(item.amount);
              const isAdvPaid = newAdvRemaining.lessThanOrEqualTo(0.01);

              await tx.financialAdvance.update({
                where: { id: adv.id },
                data: {
                  paidAmount: newAdvPaid,
                  remainingAmount: isAdvPaid ? new Prisma.Decimal(0) : newAdvRemaining,
                  status: isAdvPaid ? AdvanceStatus.PAID : AdvanceStatus.PARTIALLY_PAID,
                },
              });
            }
          }
        }
      }

      // 4. Audit Log
      await tx.auditLog.create({
        data: {
          userId: currentUserId,
          action: AuditAction.PAYROLL_FINALIZED,
          entity: 'PayrollPeriod',
          entityId: periodId,
          payload: {
            period: period.name,
            totalRecords: period.payrollRecords.length,
            remarks: dto?.remarks,
          },
        },
      });
    });

    return {
      message: `Payroll period ${period.name} finalized successfully`,
      periodId,
      finalizedAt: new Date(),
    };
  }

  async createPayrollAdjustment(recordId: string, currentUserId: string, dto: CreateAdjustmentDto) {
    const record = await this.prisma.payrollRecord.findUnique({
      where: { id: recordId },
      include: { payrollPeriod: true },
    });

    if (!record) throw new NotFoundException('Payroll record not found');

    const adjAmount = new Prisma.Decimal(dto.amount);
    if (adjAmount.lessThanOrEqualTo(0)) {
      throw new BadRequestException('Adjustment amount must be positive');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      // 1. Create adjustment entry
      const adjustment = await tx.payrollAdjustment.create({
        data: {
          payrollRecordId: recordId,
          type: dto.type,
          amount: adjAmount,
          isDeduction: dto.isDeduction || false,
          reason: dto.reason,
          status: 'APPROVED',
          approvedById: currentUserId,
        },
      });

      // 2. Add line item
      await tx.payrollLineItem.create({
        data: {
          payrollRecordId: recordId,
          type: dto.type,
          name: `Adjustment: ${dto.type.replace('_', ' ')}`,
          description: dto.reason,
          amount: adjAmount,
          isDeduction: dto.isDeduction || false,
          source: 'ADJUSTMENT',
          sourceId: adjustment.id,
        },
      });

      // 3. Recalculate record totals
      let newGross = new Prisma.Decimal(record.grossSalary);
      let newDeductions = new Prisma.Decimal(record.totalDeductions);

      if (dto.isDeduction) {
        newDeductions = newDeductions.plus(adjAmount);
      } else {
        newGross = newGross.plus(adjAmount);
      }

      let newNet = newGross.minus(newDeductions);
      if (newNet.lessThan(0)) newNet = new Prisma.Decimal(0);

      const updatedRecord = await tx.payrollRecord.update({
        where: { id: recordId },
        data: {
          grossSalary: newGross,
          totalDeductions: newDeductions,
          netSalary: newNet,
        },
      });

      // 4. Audit Log
      await tx.auditLog.create({
        data: {
          userId: currentUserId,
          action: AuditAction.PAYROLL_CORRECTED,
          entity: 'PayrollRecord',
          entityId: recordId,
          payload: {
            adjustmentId: adjustment.id,
            type: dto.type,
            amount: adjAmount,
            isDeduction: dto.isDeduction,
            reason: dto.reason,
          },
        },
      });

      return updatedRecord;
    });

    return updated;
  }

  // ============================================================
  // 5. PAYROLL QUERIES & PAYSLIP DETAILS
  // ============================================================

  async getMyPayroll(employeeProfileId: string, query: Partial<QueryPayrollDto> = {}) {
    const { page = 1, limit = 12, period } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.PayrollRecordWhereInput = {
      employeeId: employeeProfileId,
    };
    if (period) {
      where.payrollPeriod = { name: period };
    }

    const [total, data] = await Promise.all([
      this.prisma.payrollRecord.count({ where }),
      this.prisma.payrollRecord.findMany({
        where,
        skip,
        take: limit,
        orderBy: { payrollPeriod: { startDate: 'desc' } },
        include: {
          payrollPeriod: {
            select: { id: true, name: true, startDate: true, endDate: true, status: true },
          },
          lineItems: true,
        },
      }),
    ]);

    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async getPayrollRecordDetails(recordId: string, currentUser: { id: string; role: Role; employeeProfileId?: string }) {
    const record = await this.prisma.payrollRecord.findUnique({
      where: { id: recordId },
      include: {
        payrollPeriod: true,
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            department: true,
            workplace: { select: { id: true, name: true } },
          },
        },
        lineItems: {
          orderBy: [{ isDeduction: 'asc' }, { type: 'asc' }],
        },
        adjustments: true,
      },
    });

    if (!record) throw new NotFoundException('Payroll record not found');

    const isHr = ([Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER] as Role[]).includes(currentUser.role);
    const isOwner = currentUser.employeeProfileId === record.employeeId;

    if (!isHr && !isOwner) {
      throw new ForbiddenException('You do not have permission to view this payroll record');
    }

    return record;
  }

  async getHrPayroll(query: Partial<QueryPayrollDto> = {}) {
    const { page = 1, limit = 10, period, payrollPeriodId, employeeId, department, status } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.PayrollRecordWhereInput = {};
    if (status) where.status = status;
    if (employeeId) where.employeeId = employeeId;
    if (payrollPeriodId) where.payrollPeriodId = payrollPeriodId;
    if (period) where.payrollPeriod = { name: period };
    if (department) where.employee = { department };

    const [total, data] = await Promise.all([
      this.prisma.payrollRecord.count({ where }),
      this.prisma.payrollRecord.findMany({
        where,
        skip,
        take: limit,
        orderBy: { payrollPeriod: { startDate: 'desc' } },
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
          payrollPeriod: {
            select: { id: true, name: true, startDate: true, endDate: true, status: true },
          },
        },
      }),
    ]);

    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }
}
