import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { RequestsRepository } from "./requests.repository";
import { WorkflowService } from "../workflow/workflow.service";
import { ApprovalsService } from "../approvals/approvals.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  CreateRequestDto,
  QueryRequestsDto,
  ApproveRequestDto,
  RejectRequestDto,
  CancelRequestDto,
  CreateLeaveBalanceDto,
  AdjustLeaveBalanceDto,
} from "./dto";
import {
  RequestStatus,
  RequestType,
  AuditAction,
  NotificationType,
  UserStatus,
  Role,
  WorkflowAction,
} from "@prisma/client";

@Injectable()
export class RequestsService {
  private readonly logger = new Logger(RequestsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly requestsRepo: RequestsRepository,
    private readonly workflowService: WorkflowService,
    private readonly approvalsService: ApprovalsService,
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
    return new Date(
      Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()),
    );
  }

  /**
   * Helper to calculate inclusive days count between two dates
   */
  private calculateDaysCount(
    start: Date,
    end: Date,
    type: RequestType,
  ): number {
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
    const existing = await this.requestsRepo.findLeaveBalance(
      employeeId,
      leaveType,
      year,
    );

    if (existing) {
      return existing;
    }

    // Default allocations: Annual Leave = 21, Sick Leave = 15, Emergency Leave = 5, Others = 10
    let totalDays = 21;
    if (leaveType === RequestType.SICK_LEAVE) totalDays = 15;
    if (leaveType === RequestType.EMERGENCY_LEAVE) totalDays = 5;

    return this.requestsRepo.createLeaveBalance({
      employeeId,
      leaveType,
      year,
      totalDays,
      usedDays: 0,
      pendingDays: 0,
      remainingDays: totalDays,
    });
  }

  /**
   * 1. Submit a new employee request (Integrated with Workflow Engine, Idempotent, IDOR protected)
   */
  async create(userId: string, dto: CreateRequestDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    if (!user?.employeeProfile) {
      throw new BadRequestException(
        "Employee profile required to submit requests",
      );
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException(
        "Inactive or suspended employees cannot submit requests",
      );
    }

    const employeeId = user.employeeProfile.id;

    // 1. Idempotency Check
    if (dto.idempotencyKey) {
      const existingRequest = await this.requestsRepo.findByIdempotencyKey(
        dto.idempotencyKey,
      );
      if (existingRequest) {
        if (existingRequest.employeeId !== employeeId) {
          throw new ForbiddenException(
            "Idempotency key collision with another employee",
          );
        }
        return existingRequest;
      }
    }

    // 2. Date Range Validation
    const startDate = this.parseDateOnly(dto.startDate);
    const endDate = this.parseDateOnly(dto.endDate);

    if (startDate > endDate) {
      throw new BadRequestException(
        "Start date must be before or equal to end date",
      );
    }

    // 3. Time Validation for hourly permissions
    if (
      (dto.type === RequestType.PERMISSION ||
        dto.type === RequestType.LATE_EXCUSE ||
        dto.type === RequestType.EARLY_LEAVE) &&
      dto.startTime &&
      dto.endTime
    ) {
      if (
        dto.startTime >= dto.endTime &&
        startDate.getTime() === endDate.getTime()
      ) {
        throw new BadRequestException(
          "Start time must be strictly before end time",
        );
      }
    }

    // 4. Overlapping Approved Request Validation
    const conflictingApproved = await this.requestsRepo.findConflictingApproved(
      employeeId,
      startDate,
      endDate,
    );

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
      const balance = await this.ensureLeaveBalance(
        employeeId,
        dto.type,
        requestYear,
      );
      if (balance.remainingDays < daysRequested) {
        throw new BadRequestException(
          `Insufficient leave balance: You have ${balance.remainingDays} days remaining, but requested ${daysRequested} days`,
        );
      }
    }

    // 6. Match Workflow
    const workflowMatch = await this.workflowService.matchWorkflow({
      requestType: dto.type,
      departmentId: user.employeeProfile.departmentId,
      role: user.role,
      days: daysRequested,
    });

    // 7. Create Request
    const request = await this.requestsRepo.create({
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
      workflowId: workflowMatch.workflowId,
      currentStepOrder: 1,
      totalSteps: workflowMatch.totalSteps,
      metadata: dto.metadata,
    });

    // 8. Record Audit Log
    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.REQUEST_CREATED,
        entity: "Request",
        entityId: request.id,
        payload: {
          type: dto.type,
          startDate: dto.startDate,
          endDate: dto.endDate,
          daysRequested,
          workflowId: workflowMatch.workflowId,
          totalSteps: workflowMatch.totalSteps,
          idempotencyKey: dto.idempotencyKey,
        },
      },
    });

    return request;
  }

  /**
   * 2. Employee History: Get submitted requests for authenticated employee
   */
  async findMyRequests(
    employeeProfileId: string,
    query: Partial<QueryRequestsDto> = {},
  ) {
    return this.requestsRepo.findMyRequests(employeeProfileId, query);
  }

  /**
   * 3. Request Details (IDOR Protected: owner or authorized HR)
   */
  async findOne(
    requestId: string,
    currentUser: { id: string; role: Role; employeeProfileId?: string },
  ) {
    const request = await this.requestsRepo.findById(requestId);

    if (!request) {
      throw new NotFoundException("Request not found");
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
      throw new ForbiddenException(
        "You do not have permission to view this request",
      );
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
    const request = await this.requestsRepo.findById(requestId);

    if (!request) {
      throw new NotFoundException("Request not found");
    }

    const isOwner = currentUser.employeeProfileId === request.employeeId;
    const isHrAdmin =
      currentUser.role === Role.SUPER_ADMIN ||
      currentUser.role === Role.HR_ADMIN;

    if (!isOwner && !isHrAdmin) {
      throw new ForbiddenException("You can only cancel your own requests");
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
          rejectionReason: dto?.reason
            ? `Cancelled: ${dto.reason}`
            : "Cancelled by employee",
        },
      });

      await tx.auditLog.create({
        data: {
          userId: currentUser.id,
          action: AuditAction.REQUEST_CANCELLED,
          entity: "Request",
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
    return this.requestsRepo.findAll(query);
  }

  /**
   * 6. Approve Request (Backward compatible endpoint: routes to Approvals Engine)
   */
  async approve(
    requestId: string,
    approverUserId: string,
    dto?: ApproveRequestDto,
  ) {
    return this.approvalsService.processApprovalStep(
      requestId,
      approverUserId,
      {
        action: WorkflowAction.APPROVE,
        comment: dto?.comment || "Approved by HR",
      },
    );
  }

  /**
   * 7. Reject Request (Backward compatible endpoint: routes to Approvals Engine)
   */
  async reject(
    requestId: string,
    approverUserId: string,
    dto: RejectRequestDto,
  ) {
    return this.approvalsService.processApprovalStep(
      requestId,
      approverUserId,
      {
        action: WorkflowAction.REJECT,
        rejectionReason: dto.reason,
      },
    );
  }

  /**
   * Backward compatibility alias for processRequest
   */
  async processRequest(
    requestId: string,
    action: "APPROVE" | "REJECT",
    approverUserId: string,
    comment?: string,
  ) {
    if (action === "APPROVE") {
      return this.approve(requestId, approverUserId, { comment });
    } else {
      return this.reject(requestId, approverUserId, {
        reason: comment || "Rejected by HR",
      });
    }
  }

  /**
   * 8. Leave Balance: Get balances for authenticated employee
   */
  async getMyLeaveBalances(employeeProfileId: string, year?: number) {
    const targetYear = year || new Date().getUTCFullYear();

    await this.ensureLeaveBalance(
      employeeProfileId,
      RequestType.ANNUAL_LEAVE,
      targetYear,
    );
    await this.ensureLeaveBalance(
      employeeProfileId,
      RequestType.SICK_LEAVE,
      targetYear,
    );
    await this.ensureLeaveBalance(
      employeeProfileId,
      RequestType.EMERGENCY_LEAVE,
      targetYear,
    );

    return this.requestsRepo.findLeaveBalancesByEmployee(
      employeeProfileId,
      targetYear,
    );
  }

  /**
   * 9. Leave Balance: Get balances for specific employee (HR only)
   */
  async getEmployeeLeaveBalances(employeeId: string, year?: number) {
    const targetYear = year || new Date().getUTCFullYear();

    await this.ensureLeaveBalance(
      employeeId,
      RequestType.ANNUAL_LEAVE,
      targetYear,
    );

    return this.requestsRepo.findLeaveBalancesByEmployee(
      employeeId,
      targetYear,
    );
  }

  /**
   * 10. Leave Balance: Create / Allocate leave balance (HR only)
   */
  async createLeaveBalance(dto: CreateLeaveBalanceDto, currentUserId: string) {
    const existing = await this.requestsRepo.findLeaveBalance(
      dto.employeeId,
      dto.leaveType,
      dto.year,
    );

    if (existing) {
      throw new BadRequestException(
        "Leave balance for this employee, type, and year already exists",
      );
    }

    const balance = await this.requestsRepo.createLeaveBalance({
      employeeId: dto.employeeId,
      leaveType: dto.leaveType,
      year: dto.year,
      totalDays: dto.totalDays,
      usedDays: 0,
      pendingDays: 0,
      remainingDays: dto.totalDays,
    });

    await this.prisma.auditLog.create({
      data: {
        userId: currentUserId,
        action: AuditAction.LEAVE_BALANCE_UPDATED,
        entity: "LeaveBalance",
        entityId: balance.id,
        payload: { ...dto },
      },
    });

    return balance;
  }

  /**
   * 11. Leave Balance: Adjust existing leave balance (HR only)
   */
  async adjustLeaveBalance(
    id: string,
    dto: AdjustLeaveBalanceDto,
    currentUserId: string,
  ) {
    const existing = await this.prisma.leaveBalance.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException("Leave balance record not found");
    }

    const totalDays =
      dto.totalDays !== undefined ? dto.totalDays : existing.totalDays;
    const usedDays =
      dto.usedDays !== undefined ? dto.usedDays : existing.usedDays;
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
        entity: "LeaveBalance",
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
