import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from "@nestjs/common";
import { ServiceRequestsRepository } from "./service-requests.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { WorkflowService } from "../workflow/workflow.service";
import {
  CreateServiceRequestDto,
  AssignServiceRequestDto,
  UpdateServiceRequestStatusDto,
  ReviewServiceRequestDto,
  CreateServiceRequestCommentDto,
  QueryServiceRequestsDto,
} from "./dto";
import {
  AuditAction,
  NotificationType,
  RequestType,
  Role,
  ServiceRequestStatus,
  UserStatus,
} from "@prisma/client";

@Injectable()
export class ServiceRequestsService {
  private readonly logger = new Logger(ServiceRequestsService.name);

  constructor(
    private readonly repo: ServiceRequestsRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly workflowService: WorkflowService,
  ) {}

  // ============================================================
  // 1. CREATE SERVICE REQUEST
  // ============================================================

  async createServiceRequest(userId: string, dto: CreateServiceRequestDto) {
    const requester = await this.prisma.employeeProfile.findUnique({
      where: { userId },
      include: { user: true },
    });

    if (!requester || requester.user?.status !== UserStatus.ACTIVE) {
      throw new BadRequestException("Active employee profile required to create requests");
    }

    const department = await this.prisma.department.findUnique({
      where: { id: dto.departmentId },
      include: {
        headOfDepartment: {
          select: { userId: true },
        },
      },
    });

    if (!department || !department.isActive) {
      throw new BadRequestException("Target servicing department not found or inactive");
    }

    // Match workflow if configured
    let matchedWorkflowId: string | null = null;
    try {
      const match = await this.workflowService.matchWorkflow({
        requestType: RequestType.GENERAL_REQUEST,
        departmentId: dto.departmentId,
        role: requester.user.role,
      });
      matchedWorkflowId = match.workflowId;
    } catch {
      // Non-blocking fallback
    }

    const requestNumber = await this.repo.generateRequestNumber();

    const serviceRequest = await this.repo.createServiceRequest(
      requester.id,
      dto,
      requestNumber,
      matchedWorkflowId,
    );

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.SERVICE_REQUEST_CREATED,
        entity: "ServiceRequest",
        entityId: serviceRequest.id,
        payload: {
          requestNumber,
          title: serviceRequest.title,
          category: serviceRequest.category,
          priority: serviceRequest.priority,
          departmentId: serviceRequest.departmentId,
        },
      },
    });

    // History record
    await this.repo.addHistory(
      serviceRequest.id,
      userId,
      "CREATED",
      null,
      ServiceRequestStatus.SUBMITTED,
      "Service request submitted",
    );

    // Notify Department Head if present
    if (
      department.headOfDepartment?.userId &&
      department.headOfDepartment.userId !== userId
    ) {
      await this.notificationsService.sendNotification(
        department.headOfDepartment.userId,
        "New Service Request",
        `New ${serviceRequest.priority} priority service request: "${serviceRequest.title}" (${requestNumber})`,
        NotificationType.SERVICE_REQUEST_CREATED,
        {
          serviceRequestId: serviceRequest.id,
          requestNumber,
          priority: serviceRequest.priority,
        },
      );
    }

    return serviceRequest;
  }

  // ============================================================
  // 2. ASSIGN SERVICE REQUEST
  // ============================================================

  async assignServiceRequest(
    id: string,
    actorUserId: string,
    dto: AssignServiceRequestDto,
  ) {
    const serviceRequest = await this.repo.findServiceRequestById(id);
    if (!serviceRequest) {
      throw new NotFoundException(`Service request ${id} not found`);
    }

    if (
      serviceRequest.status === ServiceRequestStatus.COMPLETED ||
      serviceRequest.status === ServiceRequestStatus.CLOSED ||
      serviceRequest.status === ServiceRequestStatus.CANCELLED ||
      serviceRequest.status === ServiceRequestStatus.REJECTED
    ) {
      throw new BadRequestException(
        `Cannot assign request in terminal status: ${serviceRequest.status}`,
      );
    }

    const assignee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.assignedToId },
      include: { user: true },
    });

    if (!assignee || assignee.user?.status !== UserStatus.ACTIVE) {
      throw new BadRequestException("Assignee employee not found or inactive");
    }

    const oldStatus = serviceRequest.status;
    const newStatus =
      oldStatus === ServiceRequestStatus.SUBMITTED
        ? ServiceRequestStatus.ASSIGNED
        : oldStatus;

    const updated = await this.repo.updateServiceRequest(id, {
      assignedTo: { connect: { id: dto.assignedToId } },
      assignedById: actorUserId,
      assignedAt: new Date(),
      status: newStatus,
      dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
    });

    await this.repo.addHistory(
      id,
      actorUserId,
      "ASSIGNED",
      oldStatus,
      newStatus,
      dto.notes || `Assigned to ${assignee.firstName} ${assignee.lastName}`,
      { assignedToId: dto.assignedToId },
    );

    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: AuditAction.SERVICE_REQUEST_ASSIGNED,
        entity: "ServiceRequest",
        entityId: id,
        payload: {
          requestNumber: serviceRequest.requestNumber,
          assignedToId: dto.assignedToId,
          assigneeName: `${assignee.firstName} ${assignee.lastName}`,
        },
      },
    });

    // Notify assignee
    if (assignee.userId && assignee.userId !== actorUserId) {
      await this.notificationsService.sendNotification(
        assignee.userId,
        "Service Request Assigned",
        `You have been assigned to service request: "${serviceRequest.title}" (${serviceRequest.requestNumber})`,
        NotificationType.SERVICE_REQUEST_ASSIGNED,
        {
          serviceRequestId: id,
          requestNumber: serviceRequest.requestNumber,
          priority: serviceRequest.priority,
        },
      );
    }

    return updated;
  }

  // ============================================================
  // 3. START WORK (TRANSITION TO IN_PROGRESS)
  // ============================================================

  async startWork(id: string, actorUserId: string) {
    const serviceRequest = await this.repo.findServiceRequestById(id);
    if (!serviceRequest) {
      throw new NotFoundException(`Service request ${id} not found`);
    }

    if (
      serviceRequest.status !== ServiceRequestStatus.ASSIGNED &&
      serviceRequest.status !== ServiceRequestStatus.SUBMITTED
    ) {
      throw new BadRequestException(
        `Cannot start work from status ${serviceRequest.status}. Must be SUBMITTED or ASSIGNED.`,
      );
    }

    const oldStatus = serviceRequest.status;
    const updated = await this.repo.updateServiceRequest(id, {
      status: ServiceRequestStatus.IN_PROGRESS,
    });

    await this.repo.addHistory(
      id,
      actorUserId,
      "STATUS_CHANGE",
      oldStatus,
      ServiceRequestStatus.IN_PROGRESS,
      "Technician started working on the service request",
    );

    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: AuditAction.SERVICE_REQUEST_STATUS_CHANGED,
        entity: "ServiceRequest",
        entityId: id,
        payload: {
          oldStatus,
          newStatus: ServiceRequestStatus.IN_PROGRESS,
        },
      },
    });

    // Notify requester
    if (serviceRequest.requester?.userId) {
      await this.notificationsService.sendNotification(
        serviceRequest.requester.userId,
        "Service Request In Progress",
        `Work has started on your service request: "${serviceRequest.title}"`,
        NotificationType.SERVICE_REQUEST_STATUS_UPDATE,
        { serviceRequestId: id, status: ServiceRequestStatus.IN_PROGRESS },
      );
    }

    return updated;
  }

  // ============================================================
  // 4. COMPLETE SERVICE REQUEST
  // ============================================================

  async completeServiceRequest(
    id: string,
    actorUserId: string,
    dto: UpdateServiceRequestStatusDto,
  ) {
    const serviceRequest = await this.repo.findServiceRequestById(id);
    if (!serviceRequest) {
      throw new NotFoundException(`Service request ${id} not found`);
    }

    if (
      serviceRequest.status !== ServiceRequestStatus.IN_PROGRESS &&
      serviceRequest.status !== ServiceRequestStatus.ASSIGNED
    ) {
      throw new BadRequestException(
        `Cannot complete service request from status ${serviceRequest.status}`,
      );
    }

    if (!dto.resolutionNotes || dto.resolutionNotes.trim().length === 0) {
      throw new BadRequestException(
        "Resolution notes are required when completing a service request",
      );
    }

    const oldStatus = serviceRequest.status;
    const completedAt = new Date();

    const updated = await this.repo.updateServiceRequest(id, {
      status: ServiceRequestStatus.COMPLETED,
      completedAt,
      resolutionNotes: dto.resolutionNotes,
    });

    await this.repo.addHistory(
      id,
      actorUserId,
      "RESOLVED",
      oldStatus,
      ServiceRequestStatus.COMPLETED,
      dto.resolutionNotes,
    );

    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: AuditAction.SERVICE_REQUEST_RESOLVED,
        entity: "ServiceRequest",
        entityId: id,
        payload: {
          requestNumber: serviceRequest.requestNumber,
          resolutionNotes: dto.resolutionNotes,
        },
      },
    });

    // Notify requester to review and confirm
    if (serviceRequest.requester?.userId) {
      await this.notificationsService.sendNotification(
        serviceRequest.requester.userId,
        "Service Request Completed — Please Review",
        `Your service request "${serviceRequest.title}" has been completed. Please review and provide feedback.`,
        NotificationType.SERVICE_REQUEST_STATUS_UPDATE,
        { serviceRequestId: id, status: ServiceRequestStatus.COMPLETED },
      );
    }

    return updated;
  }

  // ============================================================
  // 5. REVIEW & SIGN-OFF (BY REQUESTER)
  // ============================================================

  async reviewServiceRequest(
    id: string,
    actorUserId: string,
    dto: ReviewServiceRequestDto,
  ) {
    const serviceRequest = await this.repo.findServiceRequestById(id);
    if (!serviceRequest) {
      throw new NotFoundException(`Service request ${id} not found`);
    }

    const actor = await this.prisma.user.findUnique({
      where: { id: actorUserId },
      include: { employeeProfile: true },
    });

    const isRequester = serviceRequest.requester?.userId === actorUserId;
    const isAdmin =
      actor?.role === Role.SUPER_ADMIN || actor?.role === Role.HR_ADMIN;

    if (!isRequester && !isAdmin) {
      throw new ForbiddenException(
        "Only the requester can submit a review for this service request",
      );
    }

    if (
      serviceRequest.status !== ServiceRequestStatus.COMPLETED &&
      serviceRequest.status !== ServiceRequestStatus.UNDER_REVIEW
    ) {
      throw new BadRequestException(
        `Review can only be performed on COMPLETED service requests. Current status: ${serviceRequest.status}`,
      );
    }

    if (dto.decision === "ACCEPT") {
      const closedAt = new Date();
      const updated = await this.repo.updateServiceRequest(id, {
        status: ServiceRequestStatus.CLOSED,
        closedAt,
        closedById: actorUserId,
        reviewRating: dto.rating,
        reviewFeedback: dto.feedback || null,
      });

      await this.repo.addHistory(
        id,
        actorUserId,
        "CLOSED",
        serviceRequest.status,
        ServiceRequestStatus.CLOSED,
        dto.feedback || `Accepted and closed with rating ${dto.rating}/5`,
        { rating: dto.rating },
      );

      await this.prisma.auditLog.create({
        data: {
          userId: actorUserId,
          action: AuditAction.SERVICE_REQUEST_CLOSED,
          entity: "ServiceRequest",
          entityId: id,
          payload: {
            rating: dto.rating,
            feedback: dto.feedback,
            closedAt,
          },
        },
      });

      // Notify assigned technician
      if (serviceRequest.assignedTo?.userId) {
        await this.notificationsService.sendNotification(
          serviceRequest.assignedTo.userId,
          "Service Request Closed",
          `Service request "${serviceRequest.title}" was accepted and closed with rating ${dto.rating}/5.`,
          NotificationType.SERVICE_REQUEST_STATUS_UPDATE,
          { serviceRequestId: id, status: ServiceRequestStatus.CLOSED },
        );
      }

      return updated;
    } else {
      // REVISION requested
      const updated = await this.repo.updateServiceRequest(id, {
        status: ServiceRequestStatus.IN_PROGRESS,
        reviewFeedback: dto.feedback || "Revision requested by customer",
      });

      await this.repo.addHistory(
        id,
        actorUserId,
        "STATUS_CHANGE",
        serviceRequest.status,
        ServiceRequestStatus.IN_PROGRESS,
        dto.feedback || "Revision requested by requester",
      );

      await this.prisma.auditLog.create({
        data: {
          userId: actorUserId,
          action: AuditAction.SERVICE_REQUEST_STATUS_CHANGED,
          entity: "ServiceRequest",
          entityId: id,
          payload: {
            decision: "REVISION",
            feedback: dto.feedback,
          },
        },
      });

      if (serviceRequest.assignedTo?.userId) {
        await this.notificationsService.sendNotification(
          serviceRequest.assignedTo.userId,
          "Revision Requested",
          `Customer requested revision on service request "${serviceRequest.title}": ${dto.feedback || "Check feedback"}`,
          NotificationType.SERVICE_REQUEST_STATUS_UPDATE,
          { serviceRequestId: id, status: ServiceRequestStatus.IN_PROGRESS },
        );
      }

      return updated;
    }
  }

  // ============================================================
  // 6. CLOSE / CANCEL / REJECT
  // ============================================================

  async closeServiceRequest(id: string, actorUserId: string, notes?: string) {
    const serviceRequest = await this.repo.findServiceRequestById(id);
    if (!serviceRequest) {
      throw new NotFoundException(`Service request ${id} not found`);
    }

    if (serviceRequest.status === ServiceRequestStatus.CLOSED) {
      throw new BadRequestException("Service request is already closed");
    }

    const closedAt = new Date();
    const updated = await this.repo.updateServiceRequest(id, {
      status: ServiceRequestStatus.CLOSED,
      closedAt,
      closedById: actorUserId,
    });

    await this.repo.addHistory(
      id,
      actorUserId,
      "CLOSED",
      serviceRequest.status,
      ServiceRequestStatus.CLOSED,
      notes || "Closed by supervisor / administration",
    );

    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: AuditAction.SERVICE_REQUEST_CLOSED,
        entity: "ServiceRequest",
        entityId: id,
        payload: { closedAt, notes },
      },
    });

    return updated;
  }

  async cancelServiceRequest(id: string, actorUserId: string, reason: string) {
    const serviceRequest = await this.repo.findServiceRequestById(id);
    if (!serviceRequest) {
      throw new NotFoundException(`Service request ${id} not found`);
    }

    if (
      serviceRequest.status === ServiceRequestStatus.COMPLETED ||
      serviceRequest.status === ServiceRequestStatus.CLOSED
    ) {
      throw new BadRequestException(
        `Cannot cancel request in ${serviceRequest.status} status`,
      );
    }

    const isRequester = serviceRequest.requester?.userId === actorUserId;
    const actor = await this.prisma.user.findUnique({
      where: { id: actorUserId },
    });
    const isAdmin =
      actor?.role === Role.SUPER_ADMIN || actor?.role === Role.HR_ADMIN;

    if (!isRequester && !isAdmin) {
      throw new ForbiddenException(
        "Only the requester or an administrator can cancel this service request",
      );
    }

    const updated = await this.repo.updateServiceRequest(id, {
      status: ServiceRequestStatus.CANCELLED,
      cancellationReason: reason,
    });

    await this.repo.addHistory(
      id,
      actorUserId,
      "CANCELLED",
      serviceRequest.status,
      ServiceRequestStatus.CANCELLED,
      reason,
    );

    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: AuditAction.SERVICE_REQUEST_CANCELLED,
        entity: "ServiceRequest",
        entityId: id,
        payload: { reason },
      },
    });

    return updated;
  }

  async rejectServiceRequest(id: string, actorUserId: string, reason: string) {
    const serviceRequest = await this.repo.findServiceRequestById(id);
    if (!serviceRequest) {
      throw new NotFoundException(`Service request ${id} not found`);
    }

    if (
      serviceRequest.status === ServiceRequestStatus.COMPLETED ||
      serviceRequest.status === ServiceRequestStatus.CLOSED ||
      serviceRequest.status === ServiceRequestStatus.CANCELLED
    ) {
      throw new BadRequestException(
        `Cannot reject request in ${serviceRequest.status} status`,
      );
    }

    const updated = await this.repo.updateServiceRequest(id, {
      status: ServiceRequestStatus.REJECTED,
      rejectionReason: reason,
    });

    await this.repo.addHistory(
      id,
      actorUserId,
      "REJECTED",
      serviceRequest.status,
      ServiceRequestStatus.REJECTED,
      reason,
    );

    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: AuditAction.SERVICE_REQUEST_STATUS_CHANGED,
        entity: "ServiceRequest",
        entityId: id,
        payload: {
          action: "REJECTED",
          reason,
        },
      },
    });

    if (serviceRequest.requester?.userId) {
      await this.notificationsService.sendNotification(
        serviceRequest.requester.userId,
        "Service Request Rejected",
        `Your service request "${serviceRequest.title}" was rejected: ${reason}`,
        NotificationType.SERVICE_REQUEST_STATUS_UPDATE,
        { serviceRequestId: id, status: ServiceRequestStatus.REJECTED },
      );
    }

    return updated;
  }

  // ============================================================
  // 7. COMMENTS & ATTACHMENTS
  // ============================================================

  async addComment(
    id: string,
    actorUserId: string,
    dto: CreateServiceRequestCommentDto,
  ) {
    const serviceRequest = await this.repo.findServiceRequestById(id);
    if (!serviceRequest) {
      throw new NotFoundException(`Service request ${id} not found`);
    }

    const actor = await this.prisma.user.findUnique({
      where: { id: actorUserId },
      include: { employeeProfile: true },
    });

    if (dto.isInternal) {
      const isStaff =
        actor?.role === Role.SUPER_ADMIN ||
        actor?.role === Role.HR_ADMIN ||
        actor?.role === Role.SUPERVISOR ||
        actor?.employeeProfile?.departmentId === serviceRequest.departmentId ||
        serviceRequest.assignedTo?.userId === actorUserId;

      if (!isStaff) {
        throw new ForbiddenException(
          "Only department servicing staff can add internal comments",
        );
      }
    }

    const comment = await this.repo.addComment(
      id,
      actorUserId,
      dto.content,
      dto.attachmentUrl,
      dto.isInternal || false,
    );

    await this.repo.addHistory(
      id,
      actorUserId,
      "NOTE_ADDED",
      serviceRequest.status,
      serviceRequest.status,
      dto.isInternal ? "Added internal note" : "Added comment",
    );

    return comment;
  }

  // ============================================================
  // 8. FIND & LIST
  // ============================================================

  async getServiceRequestById(id: string, userId: string) {
    const serviceRequest = await this.repo.findServiceRequestById(id);
    if (!serviceRequest) {
      throw new NotFoundException(`Service request ${id} not found`);
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    const isInternalStaff =
      user?.role === Role.SUPER_ADMIN ||
      user?.role === Role.HR_ADMIN ||
      user?.role === Role.SUPERVISOR ||
      user?.employeeProfile?.departmentId === serviceRequest.departmentId ||
      serviceRequest.assignedTo?.userId === userId;

    if (!isInternalStaff) {
      // Filter out internal comments from the requester view
      serviceRequest.comments = serviceRequest.comments.filter(
        (c) => !c.isInternal,
      );
    }

    return serviceRequest;
  }

  async listServiceRequests(userId: string, query: QueryServiceRequestsDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { employeeProfile: true },
    });

    if (!user) {
      throw new NotFoundException("User not found");
    }

    // Role scoping:
    if (user.role === Role.SUPER_ADMIN || user.role === Role.HR_ADMIN) {
      return this.repo.findAll(query);
    }

    if (user.role === Role.HR_MANAGER || user.role === Role.SUPERVISOR) {
      // If query specifies department, verify access or scope to user's department
      const deptId = query.departmentId || user.employeeProfile?.departmentId;
      return this.repo.findAll(query, undefined, deptId || undefined);
    }

    // Regular employee: can query their own requests or requests assigned to them
    const empId = user.employeeProfile?.id;
    if (!empId) {
      return {
        data: [],
        meta: { total: 0, page: 1, limit: query.limit || 10, totalPages: 0 },
      };
    }

    if (query.assignedToId === empId) {
      return this.repo.findAll(query, undefined, undefined);
    }

    // Default to requests submitted by the employee
    return this.repo.findAll(query, empId, undefined);
  }
}
