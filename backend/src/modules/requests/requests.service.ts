import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  CreateRequestDto,
  QueryRequestsDto,
  ApproveRequestDto,
  RejectRequestDto,
  CancelRequestDto,
  CreateLeaveBalanceDto,
  AdjustLeaveBalanceDto,
} from './dto';
import {
  RequestStatus,
  RequestType,
  AuditAction,
  NotificationType,
  AttendanceStatus,
  UserStatus,
  Prisma,
  Role,
} from '@prisma/client';

@Injectable()
export class RequestsService {
  private readonly logger = new Logger(RequestsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Helper to normalize a date string to UTC Date without time component
   */
  private parseDateOnly(dateStr: string): Date {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) {
      throw new BadRequestException(`Invalid date format: ${dateStr}`);
    }
    return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  }

  /**
   * Helper to calculate inclusive days count between two dates
   */
  private calculateDaysCount(start: Date, end: Date, type: RequestType): number {
    if (type === RequestType.HALF_DAY) {
      return 0.5;
    }
    const diffMs = end.getTime() - start.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(1, diffDays);
  }

  /**
   * Checks and ensures default LeaveBalance exists for an employee in a given year
   */
  async ensureLeaveBalance(
    employeeId: string,
    leaveType: RequestType,
    year: number,
  ) {
    const existing = await this.prisma.leaveBalance.findUnique({
      where: {
        employeeId_leaveType_year: {
          employeeId,
          leaveType,
          year,
        },
      },
    });

    if (existing) {
      return existing;
    }

    // Default allocations: Annual Leave = 21, Sick Leave = 15, Emergency Leave = 5, Others = 10
    let totalDays = 21;
    if (leaveType === RequestType.SICK_LEAVE) totalDays = 15;
    if (leaveType === RequestType.EMERGENCY_LEAVE) totalDays = 5;

    return this.prisma.leaveBalance.create({
      data: {
        employeeId,
        leaveType,
        year,
        totalDays,
        usedDays: 0,
        pendingDays: 0,
        remainingDays: totalDays,
      },
    });
  }

  /**
   * 1. Submit a new employee request (Idempotent, IDOR protected)
   */
  async create(userId: string, dto: CreateRequestDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    if (!user?.employeeProfile) {
      throw new BadRequestException('Employee profile required to submit requests');
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException('Inactive or suspended employees cannot submit requests');
    }

    const employeeId = user.employeeProfile.id;

    // 1. Idempotency Check
    if (dto.idempotencyKey) {
      const existingRequest = await this.prisma.request.findUnique({
        where: { idempotencyKey: dto.idempotencyKey },
        include: { approvalSteps: true },
      });
      if (existingRequest) {
        if (existingRequest.employeeId !== employeeId) {
          throw new ForbiddenException('Idempotency key collision with another employee');
        }
        return existingRequest;
      }
    }

    // 2. Date Range Validation
    const startDate = this.parseDateOnly(dto.startDate);
    const endDate = this.parseDateOnly(dto.endDate);

    if (startDate > endDate) {
      throw new BadRequestException('Start date must be before or equal to end date');
    }

    // 3. Time Validation for hourly permissions
    if (
      (dto.type === RequestType.PERMISSION ||
        dto.type === RequestType.LATE_EXCUSE ||
        dto.type === RequestType.EARLY_LEAVE) &&
      dto.startTime &&
      dto.endTime
    ) {
      if (dto.startTime >= dto.endTime && startDate.getTime() === endDate.getTime()) {
        throw new BadRequestException('Start time must be strictly before end time');
      }
    }

    // 4. Overlapping Approved Request Validation
    const conflictingApproved = await this.prisma.request.findFirst({
      where: {
        employeeId,
        status: RequestStatus.APPROVED,
        startDate: { lte: endDate },
        endDate: { gte: startDate },
      },
    });

    if (conflictingApproved) {
      throw new BadRequestException(
        `An approved request (${conflictingApproved.type}) already exists for this date range`,
      );
    }

    // 5. Leave Balance Pre-check (for Annual / Emergency Leave)
    const requestYear = startDate.getUTCFullYear();
    const daysRequested = this.calculateDaysCount(startDate, endDate, dto.type);

    if (
      dto.type === RequestType.ANNUAL_LEAVE ||
      dto.type === RequestType.LEAVE ||
      dto.type === RequestType.EMERGENCY_LEAVE
    ) {
      const balance = await this.ensureLeaveBalance(employeeId, dto.type, requestYear);
      if (balance.remainingDays < daysRequested) {
        throw new BadRequestException(
          `Insufficient leave balance: You have ${balance.remainingDays} days remaining, but requested ${daysRequested} days`,
        );
      }
    }

    // 6. Create Request
    const request = await this.prisma.request.create({
      data: {
        idempotencyKey: dto.idempotencyKey,
        employeeId,
        type: dto.type,
        status: RequestStatus.PENDING,
        startDate,
        endDate,
        startTime: dto.startTime,
        endTime: dto.endTime,
        halfDayPeriod: dto.halfDayPeriod,
        reason: dto.reason,
        attachmentUrl: dto.attachmentUrl,
        metadata: dto.metadata as Prisma.InputJsonValue,
      },
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
    });

    // 7. Record Audit Log
    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.REQUEST_CREATED,
        entity: 'Request',
        entityId: request.id,
        payload: {
          type: dto.type,
          startDate: dto.startDate,
          endDate: dto.endDate,
          daysRequested,
          idempotencyKey: dto.idempotencyKey,
        },
      },
    });

    return request;
  }

  /**
   * 2. Employee History: Get submitted requests for authenticated employee
   */
  async findMyRequests(employeeProfileId: string, query: Partial<QueryRequestsDto> = {}) {
    const {
      page = 1,
      limit = 10,
      status,
      type,
      startDate,
      endDate,
      search,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = query;

    const skip = (page - 1) * limit;
    const where: Prisma.RequestWhereInput = {
      employeeId: employeeProfileId,
    };

    if (status) where.status = status;
    if (type) where.type = type;

    if (startDate || endDate) {
      where.AND = [];
      if (startDate) {
        (where.AND as any[]).push({ endDate: { gte: this.parseDateOnly(startDate) } });
      }
      if (endDate) {
        (where.AND as any[]).push({ startDate: { lte: this.parseDateOnly(endDate) } });
      }
    }

    if (search) {
      where.reason = { contains: search, mode: 'insensitive' };
    }

    const [total, data] = await Promise.all([
      this.prisma.request.count({ where }),
      this.prisma.request.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          approvalSteps: {
            include: {
              approver: {
                select: {
                  id: true,
                  email: true,
                  role: true,
                },
              },
            },
          },
        },
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

  /**
   * 3. Request Details (IDOR Protected: owner or authorized HR)
   */
  async findOne(requestId: string, currentUser: { id: string; role: Role; employeeProfileId?: string }) {
    const request = await this.prisma.request.findUnique({
      where: { id: requestId },
      include: {
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            department: true,
            workplace: { select: { id: true, name: true, code: true } },
            schedule: { select: { id: true, name: true, startTime: true, endTime: true } },
          },
        },
        approvalSteps: {
          include: {
            approver: {
              select: {
                id: true,
                email: true,
                role: true,
              },
            },
          },
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!request) {
      throw new NotFoundException('Request not found');
    }

    // IDOR Check
    const hrRoles: Role[] = [
      Role.SUPER_ADMIN,
      Role.HR_ADMIN,
      Role.HR_MANAGER,
      Role.SUPERVISOR,
    ];
    const isHr = hrRoles.includes(currentUser.role);

    const isOwner = currentUser.employeeProfileId === request.employeeId;

    if (!isHr && !isOwner) {
      throw new ForbiddenException('You do not have permission to view this request');
    }

    return request;
  }

  /**
   * 4. Cancel Request (Owner Employee Only, only when PENDING)
   */
  async cancel(
    requestId: string,
    currentUser: { id: string; employeeProfileId?: string; role: Role },
    dto?: CancelRequestDto,
  ) {
    const request = await this.prisma.request.findUnique({
      where: { id: requestId },
      include: { employee: true },
    });

    if (!request) {
      throw new NotFoundException('Request not found');
    }

    const isOwner = currentUser.employeeProfileId === request.employeeId;
    const isHrAdmin = currentUser.role === Role.SUPER_ADMIN || currentUser.role === Role.HR_ADMIN;

    if (!isOwner && !isHrAdmin) {
      throw new ForbiddenException('You can only cancel your own requests');
    }

    if (request.status !== RequestStatus.PENDING) {
      throw new BadRequestException(
        `Cannot cancel request in ${request.status} status. Only PENDING requests can be cancelled.`,
      );
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const updatedRequest = await tx.request.update({
        where: { id: requestId },
        data: {
          status: RequestStatus.CANCELLED,
          rejectionReason: dto?.reason ? `Cancelled: ${dto.reason}` : 'Cancelled by employee',
        },
      });

      await tx.auditLog.create({
        data: {
          userId: currentUser.id,
          action: AuditAction.REQUEST_CANCELLED,
          entity: 'Request',
          entityId: requestId,
          payload: { reason: dto?.reason },
        },
      });

      return updatedRequest;
    });

    return updated;
  }

  /**
   * 5. HR Request Queue: List all requests with comprehensive filters
   */
  async findAll(query: Partial<QueryRequestsDto> = {}) {
    const {
      page = 1,
      limit = 10,
      status,
      type,
      employeeId,
      department,
      workplaceId,
      startDate,
      endDate,
      search,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = query;

    const skip = (page - 1) * limit;
    const where: Prisma.RequestWhereInput = {};

    if (status) where.status = status;
    if (type) where.type = type;
    if (employeeId) where.employeeId = employeeId;

    if (department || workplaceId) {
      where.employee = {};
      if (department) where.employee.department = department;
      if (workplaceId) where.employee.workplaceId = workplaceId;
    }

    if (startDate || endDate) {
      where.AND = [];
      if (startDate) {
        (where.AND as any[]).push({ endDate: { gte: this.parseDateOnly(startDate) } });
      }
      if (endDate) {
        (where.AND as any[]).push({ startDate: { lte: this.parseDateOnly(endDate) } });
      }
    }

    if (search) {
      where.OR = [
        { reason: { contains: search, mode: 'insensitive' } },
        { employee: { firstName: { contains: search, mode: 'insensitive' } } },
        { employee: { lastName: { contains: search, mode: 'insensitive' } } },
        { employee: { employeeCode: { contains: search, mode: 'insensitive' } } },
      ];
    }

    const [total, data] = await Promise.all([
      this.prisma.request.count({ where }),
      this.prisma.request.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
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
          approvalSteps: {
            include: {
              approver: { select: { id: true, email: true, role: true } },
            },
          },
        },
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

  /**
   * 6. Approve Request (Transactional: Request + LeaveBalance + Attendance Integration + Audit + Notification)
   */
  async approve(requestId: string, approverUserId: string, dto?: ApproveRequestDto) {
    const request = await this.prisma.request.findUnique({
      where: { id: requestId },
      include: {
        employee: {
          include: {
            user: true,
          },
        },
      },
    });

    if (!request) {
      throw new NotFoundException('Request not found');
    }

    if (request.status === RequestStatus.APPROVED) {
      throw new BadRequestException('Request is already approved');
    }

    if (request.status !== RequestStatus.PENDING) {
      throw new BadRequestException(
        `Cannot approve request in ${request.status} status. Only PENDING requests can be approved.`,
      );
    }

    const startDate = new Date(request.startDate);
    const endDate = new Date(request.endDate);
    const requestYear = startDate.getUTCFullYear();
    const daysRequested = this.calculateDaysCount(startDate, endDate, request.type);

    // Perform atomic transaction
    const updated = await this.prisma.$transaction(async (tx) => {
      // 1. Update Request
      const updatedReq = await tx.request.update({
        where: { id: requestId },
        data: {
          status: RequestStatus.APPROVED,
          reviewedByUserId: approverUserId,
          reviewedAt: new Date(),
          approvalSteps: {
            create: {
              approverId: approverUserId,
              status: RequestStatus.APPROVED,
              comment: dto?.comment || 'Approved by HR',
              actionDate: new Date(),
            },
          },
        },
      });

      // 2. Leave Balance Deduction
      if (
        request.type === RequestType.ANNUAL_LEAVE ||
        request.type === RequestType.LEAVE ||
        request.type === RequestType.EMERGENCY_LEAVE ||
        request.type === RequestType.SICK_LEAVE
      ) {
        const balance = await tx.leaveBalance.upsert({
          where: {
            employeeId_leaveType_year: {
              employeeId: request.employeeId,
              leaveType: request.type,
              year: requestYear,
            },
          },
          update: {
            usedDays: { increment: daysRequested },
            remainingDays: { decrement: daysRequested },
          },
          create: {
            employeeId: request.employeeId,
            leaveType: request.type,
            year: requestYear,
            totalDays: 21,
            usedDays: daysRequested,
            remainingDays: 21 - daysRequested,
          },
        });

        await tx.auditLog.create({
          data: {
            userId: approverUserId,
            action: AuditAction.LEAVE_BALANCE_UPDATED,
            entity: 'LeaveBalance',
            entityId: balance.id,
            payload: {
              employeeId: request.employeeId,
              leaveType: request.type,
              deductedDays: daysRequested,
              remainingDays: balance.remainingDays,
            },
          },
        });
      }

      // 3. Attendance Integration
      const curr = new Date(startDate.getTime());
      while (curr <= endDate) {
        const dateOnly = new Date(Date.UTC(curr.getUTCFullYear(), curr.getUTCMonth(), curr.getUTCDate()));

        if (
          request.type === RequestType.ANNUAL_LEAVE ||
          request.type === RequestType.SICK_LEAVE ||
          request.type === RequestType.UNPAID_LEAVE ||
          request.type === RequestType.EMERGENCY_LEAVE ||
          request.type === RequestType.OFFICIAL_LEAVE ||
          request.type === RequestType.LEAVE ||
          request.type === RequestType.ABSENCE
        ) {
          await tx.attendanceRecord.upsert({
            where: {
              employeeId_date: {
                employeeId: request.employeeId,
                date: dateOnly,
              },
            },
            update: {
              status: AttendanceStatus.ON_LEAVE,
              notes: `Approved ${request.type.replace('_', ' ')}: ${request.reason}`,
              verifiedByUserId: approverUserId,
            },
            create: {
              employeeId: request.employeeId,
              date: dateOnly,
              status: AttendanceStatus.ON_LEAVE,
              notes: `Approved ${request.type.replace('_', ' ')}: ${request.reason}`,
              verifiedByUserId: approverUserId,
            },
          });
        } else if (request.type === RequestType.LATE_EXCUSE) {
          const existingRecord = await tx.attendanceRecord.findUnique({
            where: {
              employeeId_date: {
                employeeId: request.employeeId,
                date: dateOnly,
              },
            },
          });
          if (existingRecord) {
            await tx.attendanceRecord.update({
              where: { id: existingRecord.id },
              data: {
                notes: `Late arrival excused by HR: ${dto?.comment || request.reason}`,
                verifiedByUserId: approverUserId,
              },
            });
          }
        } else if (
          request.type === RequestType.EARLY_LEAVE ||
          request.type === RequestType.HALF_DAY ||
          request.type === RequestType.PERMISSION ||
          request.type === RequestType.REMOTE_WORK
        ) {
          const existingRecord = await tx.attendanceRecord.findUnique({
            where: {
              employeeId_date: {
                employeeId: request.employeeId,
                date: dateOnly,
              },
            },
          });
          if (existingRecord) {
            await tx.attendanceRecord.update({
              where: { id: existingRecord.id },
              data: {
                notes: `Approved ${request.type}: ${request.reason} (${dto?.comment || 'OK'})`,
                verifiedByUserId: approverUserId,
              },
            });
          }
        }

        curr.setUTCDate(curr.getUTCDate() + 1);
      }

      // 4. Audit Log
      await tx.auditLog.create({
        data: {
          userId: approverUserId,
          action: AuditAction.REQUEST_APPROVED,
          entity: 'Request',
          entityId: requestId,
          payload: {
            comment: dto?.comment,
            daysRequested,
            type: request.type,
          },
        },
      });

      return updatedReq;
    });

    // 5. Non-blocking Push & In-app Notification
    try {
      if (request.employee?.user?.id) {
        await this.notificationsService.sendNotification(
          request.employee.user.id,
          'Request Approved',
          `Your ${request.type.replace('_', ' ')} request has been approved.`,
          NotificationType.REQUEST_STATUS_UPDATE,
          { requestId: request.id, status: RequestStatus.APPROVED },
        );
      }
    } catch (notifErr: any) {
      this.logger.warn(`Failed to dispatch notification for request ${requestId}: ${notifErr?.message || notifErr}`);
    }

    return updated;
  }

  /**
   * 7. Reject Request (Mandatory reason, Audit, Notification)
   */
  async reject(requestId: string, approverUserId: string, dto: RejectRequestDto) {
    if (!dto?.reason || dto.reason.trim().length === 0) {
      throw new BadRequestException('Rejection reason is required');
    }

    const request = await this.prisma.request.findUnique({
      where: { id: requestId },
      include: {
        employee: {
          include: {
            user: true,
          },
        },
      },
    });

    if (!request) {
      throw new NotFoundException('Request not found');
    }

    if (request.status === RequestStatus.REJECTED) {
      throw new BadRequestException('Request is already rejected');
    }

    if (request.status !== RequestStatus.PENDING) {
      throw new BadRequestException(
        `Cannot reject request in ${request.status} status. Only PENDING requests can be rejected.`,
      );
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const updatedReq = await tx.request.update({
        where: { id: requestId },
        data: {
          status: RequestStatus.REJECTED,
          rejectionReason: dto.reason,
          reviewedByUserId: approverUserId,
          reviewedAt: new Date(),
          approvalSteps: {
            create: {
              approverId: approverUserId,
              status: RequestStatus.REJECTED,
              comment: dto.reason,
              actionDate: new Date(),
            },
          },
        },
      });

      await tx.auditLog.create({
        data: {
          userId: approverUserId,
          action: AuditAction.REQUEST_REJECTED,
          entity: 'Request',
          entityId: requestId,
          payload: {
            reason: dto.reason,
            type: request.type,
          },
        },
      });

      return updatedReq;
    });

    // Non-blocking notification
    try {
      if (request.employee?.user?.id) {
        await this.notificationsService.sendNotification(
          request.employee.user.id,
          'Request Rejected',
          `Your ${request.type.replace('_', ' ')} request was rejected: ${dto.reason}`,
          NotificationType.REQUEST_STATUS_UPDATE,
          { requestId: request.id, status: RequestStatus.REJECTED, reason: dto.reason },
        );
      }
    } catch (notifErr: any) {
      this.logger.warn(`Failed to dispatch rejection notification for request ${requestId}: ${notifErr?.message || notifErr}`);
    }

    return updated;
  }

  /**
   * Backward compatibility alias for processRequest
   */
  async processRequest(
    requestId: string,
    action: 'APPROVE' | 'REJECT',
    approverUserId: string,
    comment?: string,
  ) {
    if (action === 'APPROVE') {
      return this.approve(requestId, approverUserId, { comment });
    } else {
      return this.reject(requestId, approverUserId, {
        reason: comment || 'Rejected by HR',
      });
    }
  }

  /**
   * 8. Leave Balance: Get balances for authenticated employee
   */
  async getMyLeaveBalances(employeeProfileId: string, year?: number) {
    const targetYear = year || new Date().getUTCFullYear();

    // Ensure default annual leave balance exists
    await this.ensureLeaveBalance(employeeProfileId, RequestType.ANNUAL_LEAVE, targetYear);
    await this.ensureLeaveBalance(employeeProfileId, RequestType.SICK_LEAVE, targetYear);
    await this.ensureLeaveBalance(employeeProfileId, RequestType.EMERGENCY_LEAVE, targetYear);

    return this.prisma.leaveBalance.findMany({
      where: {
        employeeId: employeeProfileId,
        year: targetYear,
      },
      orderBy: { leaveType: 'asc' },
    });
  }

  /**
   * 9. Leave Balance: Get balances for specific employee (HR only)
   */
  async getEmployeeLeaveBalances(employeeId: string, year?: number) {
    const targetYear = year || new Date().getUTCFullYear();

    await this.ensureLeaveBalance(employeeId, RequestType.ANNUAL_LEAVE, targetYear);

    return this.prisma.leaveBalance.findMany({
      where: {
        employeeId,
        year: targetYear,
      },
      orderBy: { leaveType: 'asc' },
    });
  }

  /**
   * 10. Leave Balance: Create / Allocate leave balance (HR only)
   */
  async createLeaveBalance(dto: CreateLeaveBalanceDto, currentUserId: string) {
    const existing = await this.prisma.leaveBalance.findUnique({
      where: {
        employeeId_leaveType_year: {
          employeeId: dto.employeeId,
          leaveType: dto.leaveType,
          year: dto.year,
        },
      },
    });

    if (existing) {
      throw new BadRequestException('Leave balance for this employee, type, and year already exists');
    }

    const balance = await this.prisma.leaveBalance.create({
      data: {
        employeeId: dto.employeeId,
        leaveType: dto.leaveType,
        year: dto.year,
        totalDays: dto.totalDays,
        usedDays: 0,
        pendingDays: 0,
        remainingDays: dto.totalDays,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: currentUserId,
        action: AuditAction.LEAVE_BALANCE_UPDATED,
        entity: 'LeaveBalance',
        entityId: balance.id,
        payload: { ...dto },
      },
    });

    return balance;
  }

  /**
   * 11. Leave Balance: Adjust existing leave balance (HR only)
   */
  async adjustLeaveBalance(id: string, dto: AdjustLeaveBalanceDto, currentUserId: string) {
    const existing = await this.prisma.leaveBalance.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException('Leave balance record not found');
    }

    const totalDays = dto.totalDays !== undefined ? dto.totalDays : existing.totalDays;
    const usedDays = dto.usedDays !== undefined ? dto.usedDays : existing.usedDays;
    const remainingDays = Math.max(0, totalDays - usedDays);

    const updated = await this.prisma.leaveBalance.update({
      where: { id },
      data: {
        totalDays,
        usedDays,
        remainingDays,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: currentUserId,
        action: AuditAction.LEAVE_BALANCE_UPDATED,
        entity: 'LeaveBalance',
        entityId: id,
        payload: {
          previousTotal: existing.totalDays,
          newTotal: totalDays,
          previousUsed: existing.usedDays,
          newUsed: usedDays,
          reason: dto.reason,
        },
      },
    });

    return updated;
  }
}
