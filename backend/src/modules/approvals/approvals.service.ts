import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from "@nestjs/common";
import { ApprovalsRepository } from "./approvals.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  ProcessApprovalDto,
  CreateDelegationDto,
  QueryPendingApprovalsDto,
} from "./dto";
import {
  ApproverType,
  AttendanceStatus,
  AuditAction,
  NotificationType,
  RequestStatus,
  RequestType,
  Role,
  UserStatus,
  WorkflowAction,
} from "@prisma/client";

@Injectable()
export class ApprovalsService {
  private readonly logger = new Logger(ApprovalsService.name);

  constructor(
    private readonly approvalsRepo: ApprovalsRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

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
   * 1. Get Pending Approvals Queue for a user (as Direct Manager, Dept Head, Role, or Delegate)
   */
  async getPendingApprovals(userId: string, query: QueryPendingApprovalsDto) {
    const { page = 1, limit = 10, requestType, employeeId, startDate, endDate, search } = query;
    const skip = (page - 1) * limit;

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    if (!user) {
      throw new NotFoundException("User not found");
    }

    const activeDelegations = await this.approvalsRepo.findActiveDelegationsForDelegate(userId);
    const delegatorUserIds = activeDelegations.map((d) => d.delegatorId);

    // Find all pending requests
    const candidateRequests = await this.prisma.request.findMany({
      where: {
        status: RequestStatus.PENDING,
        ...(requestType && { type: requestType }),
        ...(employeeId && { employeeId }),
        ...(startDate && { endDate: { gte: new Date(startDate) } }),
        ...(endDate && { startDate: { lte: new Date(endDate) } }),
        ...(search && {
          OR: [
            { reason: { contains: search, mode: "insensitive" } },
            { employee: { firstName: { contains: search, mode: "insensitive" } } },
            { employee: { lastName: { contains: search, mode: "insensitive" } } },
            { employee: { employeeCode: { contains: search, mode: "insensitive" } } },
          ],
        }),
      },
      include: {
        employee: {
          select: {
            id: true,
            employeeCode: true,
            firstName: true,
            lastName: true,
            jobTitle: true,
            department: true,
            managerId: true,
            manager: { select: { id: true, userId: true } },
            departmentRel: {
              select: { id: true, headOfDepartmentId: true, headOfDepartment: { select: { userId: true } } },
            },
            section: {
              select: { id: true, headOfSectionId: true, headOfSection: { select: { userId: true } } },
            },
            workplace: { select: { id: true, name: true } },
          },
        },
        workflow: {
          include: {
            steps: { orderBy: { stepOrder: "asc" } },
          },
        },
        approvalSteps: {
          include: {
            approver: { select: { id: true, email: true, role: true } },
          },
          orderBy: { stepOrder: "asc" },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    // Filter candidate requests matching current user or active delegator permissions for current step
    const matchedRequests = candidateRequests.filter((req) => {
      return this.isUserAuthorizedForStep(user, delegatorUserIds, req, req.currentStepOrder);
    });

    const total = matchedRequests.length;
    const paginatedData = matchedRequests.slice(skip, skip + limit);

    return {
      data: paginatedData,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Helper to check if a user (or their delegators) is authorized for a specific step of a request
   */
  private isUserAuthorizedForStep(
    user: { id: string; role: Role; employeeProfile?: { id: string } | null },
    delegatorUserIds: string[],
    request: any,
    stepOrder: number,
  ): boolean {
    const isSuperAdminOrHrAdmin =
      user.role === Role.SUPER_ADMIN || user.role === Role.HR_ADMIN;
    if (isSuperAdminOrHrAdmin) {
      return true;
    }

    // Direct manager check
    const managerUserId = request.employee?.manager?.userId;
    const headOfDeptUserId = request.employee?.departmentRel?.headOfDepartment?.userId;
    const headOfSectionUserId = request.employee?.section?.headOfSection?.userId;

    const currentStepDef = request.workflow?.steps?.find((s: any) => s.stepOrder === stepOrder);

    const checkActor = (actorId: string | null | undefined) => {
      if (!actorId) return false;
      return actorId === user.id || delegatorUserIds.includes(actorId);
    };

    if (!currentStepDef) {
      // Default single-step fallback
      if (checkActor(managerUserId)) return true;
      if (checkActor(headOfDeptUserId)) return true;
      if (user.role === Role.HR_MANAGER || user.role === Role.SUPERVISOR) return true;
      return false;
    }

    switch (currentStepDef.approverType) {
      case ApproverType.DIRECT_MANAGER:
        return checkActor(managerUserId);
      case ApproverType.HEAD_OF_DEPARTMENT:
        return checkActor(headOfDeptUserId);
      case ApproverType.HEAD_OF_SECTION:
        return checkActor(headOfSectionUserId);
      case ApproverType.SPECIFIC_ROLE:
        return currentStepDef.role === user.role;
      case ApproverType.SPECIFIC_USER:
        return checkActor(currentStepDef.specificUserId);
      default:
        return false;
    }
  }

  /**
   * 2. Process Approval / Rejection Step (Multi-Level Workflow Engine)
   */
  async processApprovalStep(
    requestId: string,
    approverUserId: string,
    dto: ProcessApprovalDto,
  ) {
    const request = await this.approvalsRepo.findRequestWithDetails(requestId);

    if (!request) {
      throw new NotFoundException(`Request with ID ${requestId} not found`);
    }

    if (request.status === RequestStatus.APPROVED) {
      throw new BadRequestException("Request is already approved");
    }
    if (request.status === RequestStatus.REJECTED) {
      throw new BadRequestException("Request is already rejected");
    }
    if (request.status !== RequestStatus.PENDING) {
      throw new BadRequestException(
        `Cannot process request in ${request.status} status. Only PENDING requests can be processed.`,
      );
    }

    const approverUser = await this.prisma.user.findUnique({
      where: { id: approverUserId },
      include: { employeeProfile: true },
    });

    if (!approverUser || approverUser.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException("Approver user is inactive or not found");
    }

    // Active delegations resolution
    const activeDelegations = await this.approvalsRepo.findActiveDelegationsForDelegate(approverUserId);
    const delegatorUserIds = activeDelegations.map((d) => d.delegatorId);

    // Validate authorization for the current active step
    const currentStepOrder = request.currentStepOrder || 1;
    const isAuthorized = this.isUserAuthorizedForStep(
      approverUser,
      delegatorUserIds,
      request,
      currentStepOrder,
    );

    if (!isAuthorized) {
      throw new ForbiddenException(
        `You are not authorized to approve or reject step ${currentStepOrder} for this request`,
      );
    }

    // Check delegation info
    let isDelegated = false;
    let delegatedById: string | null = null;
    if (delegatorUserIds.length > 0) {
      const managerUserId = request.employee?.manager?.user?.id;
      const headOfDeptUserId = request.employee?.departmentRel?.headOfDepartment?.user?.id;
      if (managerUserId && delegatorUserIds.includes(managerUserId)) {
        isDelegated = true;
        delegatedById = managerUserId;
      } else if (headOfDeptUserId && delegatorUserIds.includes(headOfDeptUserId)) {
        isDelegated = true;
        delegatedById = headOfDeptUserId;
      }
    }

    // Check duplicate approval on the exact same step
    const duplicateStep = request.approvalSteps.find(
      (s) => s.stepOrder === currentStepOrder && s.approverId === approverUserId,
    );
    if (duplicateStep) {
      throw new BadRequestException(
        `Duplicate approval: you have already processed step ${currentStepOrder} for this request`,
      );
    }

    const totalSteps = request.totalSteps || request.workflow?.steps?.length || 1;
    const isFinalStep = currentStepOrder >= totalSteps;

    const startDate = new Date(request.startDate);
    const endDate = new Date(request.endDate);
    const requestYear = startDate.getUTCFullYear();
    const daysRequested = this.calculateDaysCount(startDate, endDate, request.type);

    // Atomic transaction for step processing & finalization
    const updatedRequest = await this.prisma.$transaction(async (tx) => {
      if (dto.action === WorkflowAction.REJECT) {
        if (!dto.rejectionReason || dto.rejectionReason.trim().length === 0) {
          throw new BadRequestException("Rejection reason is required when rejecting a request");
        }

        // 1. Create ApprovalStep record
        await tx.approvalStep.create({
          data: {
            requestId,
            approverId: approverUserId,
            stepOrder: currentStepOrder,
            status: RequestStatus.REJECTED,
            action: WorkflowAction.REJECT,
            comment: dto.rejectionReason,
            originalApproverId: delegatedById,
            isDelegated,
            delegatedById,
            actionDate: new Date(),
          },
        });

        // 2. Update Request Status to REJECTED
        const rejectedReq = await tx.request.update({
          where: { id: requestId },
          data: {
            status: RequestStatus.REJECTED,
            rejectionReason: dto.rejectionReason,
            reviewedByUserId: approverUserId,
            reviewedAt: new Date(),
          },
          include: {
            approvalSteps: {
              include: { approver: { select: { id: true, email: true, role: true } } },
            },
          },
        });

        // 3. Audit Log
        await tx.auditLog.create({
          data: {
            userId: approverUserId,
            action: AuditAction.REQUEST_REJECTED,
            entity: "Request",
            entityId: requestId,
            payload: {
              stepOrder: currentStepOrder,
              rejectionReason: dto.rejectionReason,
              isDelegated,
              delegatedById,
            },
          },
        });

        return rejectedReq;
      }

      // Action is APPROVE
      // 1. Create ApprovalStep record
      await tx.approvalStep.create({
        data: {
          requestId,
          approverId: approverUserId,
          stepOrder: currentStepOrder,
          status: RequestStatus.APPROVED,
          action: WorkflowAction.APPROVE,
          comment: dto.comment || "Approved",
          originalApproverId: delegatedById,
          isDelegated,
          delegatedById,
          actionDate: new Date(),
        },
      });

      if (!isFinalStep) {
        // Multi-level: Advance to next step
        const nextStepOrder = currentStepOrder + 1;
        const advancedReq = await tx.request.update({
          where: { id: requestId },
          data: {
            currentStepOrder: nextStepOrder,
          },
          include: {
            approvalSteps: {
              include: { approver: { select: { id: true, email: true, role: true } } },
            },
          },
        });

        await tx.auditLog.create({
          data: {
            userId: approverUserId,
            action: AuditAction.APPROVAL_STEP_EXECUTED,
            entity: "Request",
            entityId: requestId,
            payload: {
              completedStep: currentStepOrder,
              nextStep: nextStepOrder,
              comment: dto.comment,
              isDelegated,
            },
          },
        });

        return advancedReq;
      }

      // Final Step Reached -> FINAL APPROVAL & Domain Side Effects
      const finalApprovedReq = await tx.request.update({
        where: { id: requestId },
        data: {
          status: RequestStatus.APPROVED,
          reviewedByUserId: approverUserId,
          reviewedAt: new Date(),
        },
        include: {
          approvalSteps: {
            include: { approver: { select: { id: true, email: true, role: true } } },
          },
        },
      });

      // Side Effect 1: Leave balance deduction
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
            entity: "LeaveBalance",
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

      // Side Effect 2: Attendance synchronization
      const curr = new Date(startDate.getTime());
      while (curr <= endDate) {
        const dateOnly = new Date(
          Date.UTC(curr.getUTCFullYear(), curr.getUTCMonth(), curr.getUTCDate()),
        );

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
              notes: `Approved ${request.type.replace("_", " ")}: ${request.reason}`,
              verifiedByUserId: approverUserId,
            },
            create: {
              employeeId: request.employeeId,
              date: dateOnly,
              status: AttendanceStatus.ON_LEAVE,
              notes: `Approved ${request.type.replace("_", " ")}: ${request.reason}`,
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
                notes: `Late arrival excused by HR: ${dto.comment || request.reason}`,
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
                notes: `Approved ${request.type}: ${request.reason} (${dto.comment || "OK"})`,
                verifiedByUserId: approverUserId,
              },
            });
          }
        }

        curr.setUTCDate(curr.getUTCDate() + 1);
      }

      // Audit Log for final approval
      await tx.auditLog.create({
        data: {
          userId: approverUserId,
          action: AuditAction.REQUEST_APPROVED,
          entity: "Request",
          entityId: requestId,
          payload: {
            daysRequested,
            type: request.type,
            comment: dto.comment,
            isDelegated,
          },
        },
      });

      return finalApprovedReq;
    });

    // Non-blocking notification
    try {
      if (request.employee?.user?.id) {
        const notifTitle =
          dto.action === WorkflowAction.REJECT
            ? "Request Rejected"
            : isFinalStep
              ? "Request Approved"
              : `Request Approved (Level ${currentStepOrder}/${totalSteps})`;

        const notifBody =
          dto.action === WorkflowAction.REJECT
            ? `Your ${request.type.replace("_", " ")} request was rejected: ${dto.rejectionReason}`
            : isFinalStep
              ? `Your ${request.type.replace("_", " ")} request has been fully approved.`
              : `Your ${request.type.replace("_", " ")} request was approved at level ${currentStepOrder}.`;

        await this.notificationsService.sendNotification(
          request.employee.user.id,
          notifTitle,
          notifBody,
          NotificationType.REQUEST_STATUS_UPDATE,
          {
            requestId: request.id,
            status: updatedRequest.status,
            currentStepOrder: updatedRequest.currentStepOrder,
          },
        );
      }
    } catch (err: any) {
      this.logger.warn(`Failed to dispatch notification: ${err?.message || err}`);
    }

    return updatedRequest;
  }

  /**
   * 3. Get Full Approval History / Audit Trail for a Request
   */
  async getApprovalHistory(requestId: string) {
    return this.approvalsRepo.findApprovalHistory(requestId);
  }

  /**
   * 4. Delegation Management
   */
  async createDelegation(delegatorUserId: string, dto: CreateDelegationDto) {
    if (delegatorUserId === dto.delegateId) {
      throw new BadRequestException("You cannot delegate approval authority to yourself");
    }

    const startDate = new Date(dto.startDate);
    const endDate = new Date(dto.endDate);
    if (startDate > endDate) {
      throw new BadRequestException("Start date must be before or equal to end date");
    }

    const delegateUser = await this.prisma.user.findUnique({
      where: { id: dto.delegateId },
    });

    if (!delegateUser || delegateUser.status !== UserStatus.ACTIVE) {
      throw new BadRequestException("Delegate user is inactive or not found");
    }

    const delegation = await this.approvalsRepo.createDelegation(delegatorUserId, dto);

    await this.prisma.auditLog.create({
      data: {
        userId: delegatorUserId,
        action: AuditAction.DELEGATION_CREATED,
        entity: "ApprovalDelegation",
        entityId: delegation.id,
        payload: {
          delegateId: dto.delegateId,
          startDate: dto.startDate,
          endDate: dto.endDate,
        },
      },
    });

    return delegation;
  }

  async getMyDelegations(userId: string) {
    return this.approvalsRepo.findDelegations(userId);
  }

  async revokeDelegation(delegationId: string, userId: string) {
    const delegation = await this.prisma.approvalDelegation.findUnique({
      where: { id: delegationId },
    });

    if (!delegation) {
      throw new NotFoundException("Delegation not found");
    }

    if (delegation.delegatorId !== userId) {
      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (user?.role !== Role.SUPER_ADMIN && user?.role !== Role.HR_ADMIN) {
        throw new ForbiddenException("You can only revoke your own delegations");
      }
    }

    const updated = await this.approvalsRepo.revokeDelegation(delegationId, userId);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.DELEGATION_REVOKED,
        entity: "ApprovalDelegation",
        entityId: delegationId,
      },
    });

    return updated;
  }
}
