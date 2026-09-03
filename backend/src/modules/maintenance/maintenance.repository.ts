import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  CreateMaintenanceRequestDto,
  UpdateMaintenanceRequestDto,
  CreateWorkOrderDto,
  UpdateWorkOrderDto,
  CreateSparePartDto,
  QueryMaintenanceRequestsDto,
  QueryWorkOrdersDto,
} from "./dto";
import { Prisma } from "@prisma/client";

@Injectable()
export class MaintenanceRepository {
  constructor(private readonly prisma: PrismaService) {}

  async generateRequestNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.maintenanceRequest.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `MR-${today}-${seq}`;
  }

  async generateOrderNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.workOrder.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `WO-${today}-${seq}`;
  }

  // ============================================================
  // MAINTENANCE REQUESTS
  // ============================================================

  async createRequest(requesterProfileId: string, dto: CreateMaintenanceRequestDto, requestNumber: string) {
    return this.prisma.maintenanceRequest.create({
      data: {
        requestNumber,
        title: dto.title,
        description: dto.description,
        type: dto.type,
        priority: dto.priority,
        assetId: dto.assetId,
        requesterId: requesterProfileId,
        departmentId: dto.departmentId,
        scheduledDate: dto.scheduledDate ? new Date(dto.scheduledDate) : null,
      },
      include: {
        asset: true,
        department: true,
        requester: {
          include: { user: { select: { email: true } } },
        },
      },
    });
  }

  async findRequestById(id: string) {
    return this.prisma.maintenanceRequest.findUnique({
      where: { id },
      include: {
        asset: true,
        department: true,
        requester: {
          include: { user: { select: { email: true } } },
        },
        workOrders: {
          include: {
            technician: {
              include: { user: { select: { email: true } } },
            },
            spareParts: {
              include: { sparePart: true },
            },
          },
        },
      },
    });
  }

  async findRequests(query: QueryMaintenanceRequestsDto) {
    const { page = 1, limit = 20, search, status, type, priority, departmentId, assetId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.MaintenanceRequestWhereInput = {};
    if (status) where.status = status;
    if (type) where.type = type;
    if (priority) where.priority = priority;
    if (departmentId) where.departmentId = departmentId;
    if (assetId) where.assetId = assetId;
    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
        { requestNumber: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.maintenanceRequest.count({ where }),
      this.prisma.maintenanceRequest.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          asset: true,
          department: true,
          requester: {
            include: { user: { select: { email: true } } },
          },
          workOrders: {
            select: { id: true, orderNumber: true, status: true },
          },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async updateRequest(id: string, dto: UpdateMaintenanceRequestDto) {
    const data: Prisma.MaintenanceRequestUpdateInput = {};
    if (dto.status !== undefined) {
      data.status = dto.status;
      if (dto.status === "COMPLETED") {
        data.completedAt = new Date();
      }
    }
    if (dto.priority !== undefined) data.priority = dto.priority;
    if (dto.resolutionNotes !== undefined) data.resolutionNotes = dto.resolutionNotes;
    if (dto.scheduledDate !== undefined) data.scheduledDate = dto.scheduledDate ? new Date(dto.scheduledDate) : null;

    return this.prisma.maintenanceRequest.update({
      where: { id },
      data,
      include: {
        asset: true,
        department: true,
        requester: {
          include: { user: { select: { email: true } } },
        },
      },
    });
  }

  // ============================================================
  // WORK ORDERS
  // ============================================================

  async createWorkOrder(dto: CreateWorkOrderDto, orderNumber: string) {
    return this.prisma.workOrder.create({
      data: {
        orderNumber,
        maintenanceRequestId: dto.maintenanceRequestId,
        title: dto.title,
        description: dto.description,
        priority: dto.priority,
        status: dto.status,
        technicianId: dto.technicianId,
        estimatedHours: dto.estimatedHours !== undefined ? new Prisma.Decimal(dto.estimatedHours) : null,
        notes: dto.notes,
      },
      include: {
        technician: {
          include: { user: { select: { email: true } } },
        },
        maintenanceRequest: true,
      },
    });
  }

  async findWorkOrderById(id: string) {
    return this.prisma.workOrder.findUnique({
      where: { id },
      include: {
        technician: {
          include: { user: { select: { email: true } } },
        },
        maintenanceRequest: {
          include: { asset: true, department: true },
        },
        spareParts: {
          include: { sparePart: true },
        },
      },
    });
  }

  async findWorkOrders(query: QueryWorkOrdersDto) {
    const { page = 1, limit = 20, search, status, priority, technicianId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.WorkOrderWhereInput = {};
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (technicianId) where.technicianId = technicianId;
    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
        { orderNumber: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.workOrder.count({ where }),
      this.prisma.workOrder.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          technician: {
            include: { user: { select: { email: true } } },
          },
          maintenanceRequest: {
            select: { id: true, requestNumber: true, title: true },
          },
          spareParts: {
            include: { sparePart: true },
          },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async updateWorkOrder(id: string, dto: UpdateWorkOrderDto) {
    const data: Prisma.WorkOrderUpdateInput = {};
    if (dto.status !== undefined) data.status = dto.status;
    if (dto.priority !== undefined) data.priority = dto.priority;
    if (dto.notes !== undefined) data.notes = dto.notes;
    if (dto.actualHours !== undefined) data.actualHours = dto.actualHours !== null ? new Prisma.Decimal(dto.actualHours) : null;
    if (dto.cost !== undefined) data.cost = dto.cost !== null ? new Prisma.Decimal(dto.cost) : null;
    if (dto.technicianId !== undefined) {
      data.technician = dto.technicianId ? { connect: { id: dto.technicianId } } : { disconnect: true };
    }

    return this.prisma.workOrder.update({
      where: { id },
      data,
      include: {
        technician: {
          include: { user: { select: { email: true } } },
        },
        maintenanceRequest: true,
      },
    });
  }

  // ============================================================
  // SPARE PARTS
  // ============================================================

  async createSparePart(dto: CreateSparePartDto) {
    return this.prisma.sparePart.create({
      data: {
        partNumber: dto.partNumber,
        name: dto.name,
        description: dto.description,
        category: dto.category,
        unitOfMeasure: dto.unitOfMeasure || "PCS",
        unitCost: dto.unitCost !== undefined ? new Prisma.Decimal(dto.unitCost) : new Prisma.Decimal(0),
        quantityOnHand: dto.quantityOnHand || 0,
        minQuantity: dto.minQuantity || 5,
      },
    });
  }

  async findSpareParts() {
    return this.prisma.sparePart.findMany({
      orderBy: { name: "asc" },
    });
  }

  async findSparePartById(id: string) {
    return this.prisma.sparePart.findUnique({
      where: { id },
    });
  }

  async findSparePartByNumber(partNumber: string) {
    return this.prisma.sparePart.findUnique({
      where: { partNumber },
    });
  }

  async consumeSparePart(workOrderId: string, sparePartId: string, quantity: number, unitCost: number) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Decrement spare part quantity
      const updatedPart = await tx.sparePart.update({
        where: { id: sparePartId },
        data: {
          quantityOnHand: { decrement: quantity },
        },
      });

      // 2. Add record to work_order_spare_parts
      const record = await tx.workOrderSparePart.create({
        data: {
          workOrderId,
          sparePartId,
          quantityUsed: quantity,
          unitCost: new Prisma.Decimal(unitCost),
        },
        include: { sparePart: true },
      });

      // 3. Update total cost in WorkOrder
      const partCost = Number(unitCost) * quantity;
      await tx.workOrder.update({
        where: { id: workOrderId },
        data: {
          cost: { increment: partCost },
        },
      });

      return { record, updatedPart };
    });
  }
}
