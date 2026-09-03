import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  Logger,
} from "@nestjs/common";
import { MaintenanceRepository } from "./maintenance.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  CreateMaintenanceRequestDto,
  UpdateMaintenanceRequestDto,
  CreateWorkOrderDto,
  UpdateWorkOrderDto,
  CreateSparePartDto,
  ConsumeSparePartDto,
  QueryMaintenanceRequestsDto,
  QueryWorkOrdersDto,
} from "./dto";
import { AuditAction, AssetStatus, MaintenanceRequestStatus, UserStatus, NotificationType } from "@prisma/client";

@Injectable()
export class MaintenanceService {
  private readonly logger = new Logger(MaintenanceService.name);

  constructor(
    private readonly repo: MaintenanceRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ============================================================
  // MAINTENANCE REQUESTS
  // ============================================================

  async createRequest(userId: string, dto: CreateMaintenanceRequestDto) {
    const requester = await this.prisma.employeeProfile.findUnique({
      where: { userId },
      include: { user: true },
    });

    if (!requester || requester.user?.status !== UserStatus.ACTIVE) {
      throw new BadRequestException("Active employee profile required to report maintenance");
    }

    if (dto.assetId) {
      const asset = await this.prisma.asset.findUnique({ where: { id: dto.assetId } });
      if (!asset) {
        throw new NotFoundException(`Asset '${dto.assetId}' not found`);
      }
      // Set asset to UNDER_MAINTENANCE
      await this.prisma.asset.update({
        where: { id: dto.assetId },
        data: { status: AssetStatus.UNDER_MAINTENANCE },
      });
    }

    const department = await this.prisma.department.findUnique({ where: { id: dto.departmentId } });
    if (!department || !department.isActive) {
      throw new BadRequestException("Target department not found or inactive");
    }

    const requestNumber = await this.repo.generateRequestNumber();
    const request = await this.repo.createRequest(requester.id, dto, requestNumber);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "MaintenanceRequest",
        entityId: request.id,
        payload: { requestNumber, title: request.title, priority: request.priority },
      },
    });

    return request;
  }

  async findRequests(query: QueryMaintenanceRequestsDto) {
    return this.repo.findRequests(query);
  }

  async findRequestById(id: string) {
    const request = await this.repo.findRequestById(id);
    if (!request) {
      throw new NotFoundException(`Maintenance request '${id}' not found`);
    }
    return request;
  }

  async updateRequest(id: string, userId: string, dto: UpdateMaintenanceRequestDto) {
    const existing = await this.findRequestById(id);
    const updated = await this.repo.updateRequest(id, dto);

    // If completed and tied to an asset, return asset to ACTIVE
    if (dto.status === MaintenanceRequestStatus.COMPLETED && existing.assetId) {
      await this.prisma.asset.update({
        where: { id: existing.assetId },
        data: { status: AssetStatus.ACTIVE },
      });
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "MaintenanceRequest",
        entityId: id,
        payload: { previousStatus: existing.status, newStatus: updated.status, changes: dto },
      },
    });

    return updated;
  }

  // ============================================================
  // WORK ORDERS
  // ============================================================

  async createWorkOrder(userId: string, dto: CreateWorkOrderDto) {
    if (dto.maintenanceRequestId) {
      const req = await this.repo.findRequestById(dto.maintenanceRequestId);
      if (!req) {
        throw new NotFoundException(`Maintenance request '${dto.maintenanceRequestId}' not found`);
      }
    }

    if (dto.technicianId) {
      const tech = await this.prisma.employeeProfile.findUnique({
        where: { id: dto.technicianId },
        include: { user: true },
      });
      if (!tech) {
        throw new NotFoundException(`Technician '${dto.technicianId}' not found`);
      }
    }

    const orderNumber = await this.repo.generateOrderNumber();
    const workOrder = await this.repo.createWorkOrder(dto, orderNumber);

    // Notify technician if assigned
    if (dto.technicianId) {
      const tech = await this.prisma.employeeProfile.findUnique({
        where: { id: dto.technicianId },
        select: { userId: true },
      });
      if (tech) {
        await this.notificationsService.sendInAppNotification({
          userId: tech.userId,
          title: "New Work Order Assigned",
          body: `You have been assigned to work order ${orderNumber}: ${dto.title}`,
          type: NotificationType.TASK_ASSIGNED,
          data: { workOrderId: workOrder.id, orderNumber },
        }).catch(() => {});
      }
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "WorkOrder",
        entityId: workOrder.id,
        payload: { orderNumber, title: workOrder.title },
      },
    });

    return workOrder;
  }

  async findWorkOrders(query: QueryWorkOrdersDto) {
    return this.repo.findWorkOrders(query);
  }

  async findWorkOrderById(id: string) {
    const workOrder = await this.repo.findWorkOrderById(id);
    if (!workOrder) {
      throw new NotFoundException(`Work order '${id}' not found`);
    }
    return workOrder;
  }

  async updateWorkOrder(id: string, userId: string, dto: UpdateWorkOrderDto) {
    await this.findWorkOrderById(id);
    const updated = await this.repo.updateWorkOrder(id, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "WorkOrder",
        entityId: id,
        payload: { changes: dto, newStatus: updated.status },
      },
    });

    return updated;
  }

  // ============================================================
  // SPARE PARTS
  // ============================================================

  async createSparePart(userId: string, dto: CreateSparePartDto) {
    const existing = await this.repo.findSparePartByNumber(dto.partNumber);
    if (existing) {
      throw new ConflictException(`Spare part with number '${dto.partNumber}' already exists`);
    }

    const part = await this.repo.createSparePart(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "SparePart",
        entityId: part.id,
        payload: { partNumber: part.partNumber, name: part.name },
      },
    });

    return part;
  }

  async findSpareParts() {
    return this.repo.findSpareParts();
  }

  async consumeSparePart(workOrderId: string, userId: string, dto: ConsumeSparePartDto) {
    await this.findWorkOrderById(workOrderId);

    const part = await this.repo.findSparePartById(dto.sparePartId);
    if (!part) {
      throw new NotFoundException(`Spare part '${dto.sparePartId}' not found`);
    }

    if (part.quantityOnHand < dto.quantity) {
      throw new BadRequestException(
        `Insufficient stock for '${part.name}'. Available: ${part.quantityOnHand}, Requested: ${dto.quantity}`,
      );
    }

    const result = await this.repo.consumeSparePart(
      workOrderId,
      dto.sparePartId,
      dto.quantity,
      Number(part.unitCost),
    );

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "WorkOrderSparePart",
        entityId: result.record.id,
        payload: {
          workOrderId,
          sparePartId: dto.sparePartId,
          quantity: dto.quantity,
          remainingStock: result.updatedPart.quantityOnHand,
        },
      },
    });

    return result;
  }
}
