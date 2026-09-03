import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from "@nestjs/common";
import { HandoverRepository } from "./handover.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  CreateHandoverDto,
  AcknowledgeHandoverDto,
  AddHandoverItemDto,
  QueryHandoversDto,
} from "./dto";
import {
  AuditAction,
  HandoverStatus,
  NotificationType,
  Role,
  UserStatus,
} from "@prisma/client";

@Injectable()
export class HandoverService {
  private readonly logger = new Logger(HandoverService.name);

  constructor(
    private readonly repo: HandoverRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ============================================================
  // 1. CREATE SHIFT HANDOVER
  // ============================================================

  async createHandover(actorUserId: string, dto: CreateHandoverDto) {
    const actor = await this.prisma.user.findUnique({
      where: { id: actorUserId },
      include: { employeeProfile: true },
    });

    if (
      !actor?.employeeProfile ||
      actor.status !== UserStatus.ACTIVE
    ) {
      throw new BadRequestException("Active employee profile required to create shift handovers");
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
      throw new BadRequestException("Department not found or inactive");
    }

    if (dto.receivedById) {
      const receiver = await this.prisma.employeeProfile.findUnique({
        where: { id: dto.receivedById },
        include: { user: true },
      });

      if (!receiver || receiver.user?.status !== UserStatus.ACTIVE) {
        throw new BadRequestException("Receiving employee not found or inactive");
      }

      if (receiver.id === actor.employeeProfile.id) {
        throw new BadRequestException("Cannot hand over a shift to yourself");
      }
    }

    // Auto-capture open tasks if requested (defaults to true)
    let autoCapturedTasks: any[] = [];
    if (dto.includeOpenTasks !== false) {
      autoCapturedTasks = await this.repo.findOpenDepartmentTasks(
        dto.departmentId,
        dto.workplaceId,
      );
    }

    const handoverNumber = await this.repo.generateHandoverNumber();

    const handover = await this.repo.createHandover(
      actor.employeeProfile.id,
      dto,
      handoverNumber,
      autoCapturedTasks,
    );

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: AuditAction.HANDOVER_CREATED,
        entity: "ShiftHandover",
        entityId: handover.id,
        payload: {
          handoverNumber,
          shiftDate: dto.shiftDate,
          shiftName: dto.shiftName,
          departmentId: dto.departmentId,
          receivedById: dto.receivedById,
          itemsCount: handover.items.length,
        },
      },
    });

    // Notify receiver if specified
    if (handover.receivedBy?.userId) {
      await this.notificationsService.sendNotification(
        handover.receivedBy.userId,
        "Shift Handover Ready for Review",
        `Shift handover for ${dto.shiftName} (${dto.shiftDate}) submitted by ${actor.employeeProfile.firstName} ${actor.employeeProfile.lastName}. Please review and acknowledge.`,
        NotificationType.HANDOVER_SUBMITTED,
        {
          handoverId: handover.id,
          handoverNumber,
          shiftDate: dto.shiftDate,
        },
      );
    } else if (department.headOfDepartment?.userId) {
      // Or notify department supervisor
      await this.notificationsService.sendNotification(
        department.headOfDepartment.userId,
        "Shift Handover Logged",
        `Shift handover for ${dto.shiftName} submitted in department ${department.name}.`,
        NotificationType.HANDOVER_SUBMITTED,
        {
          handoverId: handover.id,
          handoverNumber,
        },
      );
    }

    return handover;
  }

  // ============================================================
  // 2. ACKNOWLEDGE / FLAG / REJECT HANDOVER
  // ============================================================

  async acknowledgeHandover(
    id: string,
    actorUserId: string,
    dto: AcknowledgeHandoverDto,
  ) {
    const handover = await this.repo.findHandoverById(id);
    if (!handover) {
      throw new NotFoundException(`Shift handover ${id} not found`);
    }

    if (handover.status === HandoverStatus.ACKNOWLEDGED) {
      throw new BadRequestException(
        "Shift handover has already been acknowledged and cannot be modified",
      );
    }

    const actor = await this.prisma.user.findUnique({
      where: { id: actorUserId },
      include: { employeeProfile: true },
    });

    if (!actor || actor.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException("Active user required to acknowledge handovers");
    }

    // Authorization: Designated receiver, department head, or admin
    const isDesignatedReceiver =
      handover.receivedBy && handover.receivedBy.userId === actorUserId;
    const isDeptHead =
      handover.department?.headOfDepartmentId === actor.employeeProfile?.id;
    const isAdmin =
      actor.role === Role.SUPER_ADMIN || actor.role === Role.HR_ADMIN;
    const isDeptMember =
      actor.employeeProfile?.departmentId === handover.departmentId &&
      !handover.receivedById; // Unassigned receiver scenario

    if (!isDesignatedReceiver && !isDeptHead && !isAdmin && !isDeptMember) {
      throw new ForbiddenException(
        "Only the designated receiving employee or department supervisor can acknowledge this handover",
      );
    }

    // Outgoing person cannot acknowledge their own handover
    if (handover.handedOverBy?.userId === actorUserId && !isAdmin) {
      throw new BadRequestException("You cannot acknowledge your own handover");
    }

    let nextStatus: HandoverStatus;
    let auditAction: AuditAction;

    if (dto.action === "ACKNOWLEDGE") {
      nextStatus = HandoverStatus.ACKNOWLEDGED;
      auditAction = AuditAction.HANDOVER_ACKNOWLEDGED;
    } else if (dto.action === "FLAG") {
      if (!dto.discrepancyNotes || dto.discrepancyNotes.trim().length === 0) {
        throw new BadRequestException("Discrepancy notes required when flagging a handover");
      }
      nextStatus = HandoverStatus.FLAGGED;
      auditAction = AuditAction.HANDOVER_DISPUTED;
    } else {
      if (!dto.discrepancyNotes || dto.discrepancyNotes.trim().length === 0) {
        throw new BadRequestException("Discrepancy notes required when rejecting a handover");
      }
      nextStatus = HandoverStatus.REJECTED;
      auditAction = AuditAction.HANDOVER_DISPUTED;
    }

    const updateData: any = {
      status: nextStatus,
      acknowledgedAt: new Date(),
      acknowledgementNotes: dto.acknowledgementNotes || null,
      discrepancyNotes: dto.discrepancyNotes || null,
    };

    // If handover did not have a receiving employee set, bind the acknowledging employee
    if (!handover.receivedById && actor.employeeProfile) {
      updateData.receivedTo = { connect: { id: actor.employeeProfile.id } };
    }

    const updated = await this.repo.updateHandover(id, updateData);

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        userId: actorUserId,
        action: auditAction,
        entity: "ShiftHandover",
        entityId: id,
        payload: {
          handoverNumber: handover.handoverNumber,
          action: dto.action,
          status: nextStatus,
          acknowledgementNotes: dto.acknowledgementNotes,
          discrepancyNotes: dto.discrepancyNotes,
        },
      },
    });

    // Notify outgoing shift leader
    if (handover.handedOverBy?.userId) {
      const msg =
        dto.action === "ACKNOWLEDGE"
          ? `Shift handover ${handover.handoverNumber} was acknowledged by next shift.`
          : `Shift handover ${handover.handoverNumber} was ${dto.action.toLowerCase()} with notes: ${dto.discrepancyNotes}`;

      await this.notificationsService.sendNotification(
        handover.handedOverBy.userId,
        `Shift Handover ${dto.action}`,
        msg,
        NotificationType.HANDOVER_ACKNOWLEDGED,
        {
          handoverId: id,
          status: nextStatus,
        },
      );
    }

    return updated;
  }

  // ============================================================
  // 3. ADD HANDOVER ITEM
  // ============================================================

  async addItem(id: string, actorUserId: string, dto: AddHandoverItemDto) {
    const handover = await this.repo.findHandoverById(id);
    if (!handover) {
      throw new NotFoundException(`Shift handover ${id} not found`);
    }

    if (handover.status === HandoverStatus.ACKNOWLEDGED) {
      throw new BadRequestException(
        "Cannot add items to an already acknowledged shift handover",
      );
    }

    return this.repo.addItem(id, dto);
  }

  // ============================================================
  // 4. GET & LIST
  // ============================================================

  async getHandoverById(id: string) {
    const handover = await this.repo.findHandoverById(id);
    if (!handover) {
      throw new NotFoundException(`Shift handover ${id} not found`);
    }
    return handover;
  }

  async listHandovers(actorUserId: string, query: QueryHandoversDto) {
    const actor = await this.prisma.user.findUnique({
      where: { id: actorUserId },
      include: { employeeProfile: true },
    });

    if (!actor) {
      throw new NotFoundException("User not found");
    }

    // Role scoping:
    if (actor.role === Role.SUPER_ADMIN || actor.role === Role.HR_ADMIN) {
      return this.repo.findAll(query);
    }

    if (actor.role === Role.HR_MANAGER || actor.role === Role.SUPERVISOR) {
      const deptId = query.departmentId || actor.employeeProfile?.departmentId;
      return this.repo.findAll(query, deptId || undefined);
    }

    // Regular employee: returns handovers of their department
    const deptId = actor.employeeProfile?.departmentId;
    return this.repo.findAll(query, deptId || undefined, actor.employeeProfile?.id);
  }
}
