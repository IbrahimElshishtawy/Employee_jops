import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  CreateWarehouseDto,
  CreateStockCategoryDto,
  CreateStockItemDto,
  UpdateStockItemDto,
  CreateStockMovementDto,
  CreateStockCountDto,
  QueryStockItemsDto,
  QueryStockMovementsDto,
} from "./dto";
import { Prisma, StockMovementType } from "@prisma/client";

@Injectable()
export class InventoryRepository {
  constructor(private readonly prisma: PrismaService) {}

  async generateMovementNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.stockMovement.count();
    const seq = (count + 1).toString().padStart(5, "0");
    return `SM-${today}-${seq}`;
  }

  async generateCountNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.stockCount.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `SC-${today}-${seq}`;
  }

  // ============================================================
  // WAREHOUSES
  // ============================================================

  async createWarehouse(dto: CreateWarehouseDto) {
    return this.prisma.warehouse.create({
      data: {
        code: dto.code,
        name: dto.name,
        location: dto.location,
        departmentId: dto.departmentId,
        isActive: dto.isActive !== undefined ? dto.isActive : true,
      },
      include: { department: true },
    });
  }

  async findWarehouses() {
    return this.prisma.warehouse.findMany({
      include: {
        department: true,
        _count: { select: { stockItems: true } },
      },
      orderBy: { name: "asc" },
    });
  }

  async findWarehouseById(id: string) {
    return this.prisma.warehouse.findUnique({
      where: { id },
      include: { department: true },
    });
  }

  async findWarehouseByCode(code: string) {
    return this.prisma.warehouse.findUnique({
      where: { code },
    });
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  async createStockCategory(dto: CreateStockCategoryDto) {
    return this.prisma.stockCategory.create({
      data: {
        code: dto.code,
        name: dto.name,
        description: dto.description,
      },
    });
  }

  async findStockCategories() {
    return this.prisma.stockCategory.findMany({
      include: {
        _count: { select: { items: true } },
      },
      orderBy: { name: "asc" },
    });
  }

  async findStockCategoryById(id: string) {
    return this.prisma.stockCategory.findUnique({
      where: { id },
    });
  }

  // ============================================================
  // STOCK ITEMS
  // ============================================================

  async createStockItem(dto: CreateStockItemDto) {
    return this.prisma.stockItem.create({
      data: {
        sku: dto.sku,
        barcode: dto.barcode,
        name: dto.name,
        description: dto.description,
        categoryId: dto.categoryId,
        warehouseId: dto.warehouseId,
        unitOfMeasure: dto.unitOfMeasure || "PCS",
        unitPrice:
          dto.unitPrice !== undefined
            ? new Prisma.Decimal(dto.unitPrice)
            : new Prisma.Decimal(0),
        costPrice:
          dto.costPrice !== undefined
            ? new Prisma.Decimal(dto.costPrice)
            : new Prisma.Decimal(0),
        quantityOnHand: dto.quantityOnHand || 0,
        minThreshold: dto.minThreshold !== undefined ? dto.minThreshold : 10,
        maxThreshold: dto.maxThreshold !== undefined ? dto.maxThreshold : 500,
        reorderLevel: dto.reorderLevel !== undefined ? dto.reorderLevel : 20,
        isActive: dto.isActive !== undefined ? dto.isActive : true,
      },
      include: {
        category: true,
        warehouse: true,
      },
    });
  }

  async findStockItemById(id: string) {
    return this.prisma.stockItem.findUnique({
      where: { id },
      include: {
        category: true,
        warehouse: true,
      },
    });
  }

  async findStockItemBySku(sku: string) {
    return this.prisma.stockItem.findUnique({
      where: { sku },
    });
  }

  async findStockItems(query: QueryStockItemsDto) {
    const {
      page = 1,
      limit = 20,
      search,
      warehouseId,
      categoryId,
      lowStock,
    } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.StockItemWhereInput = {};
    if (warehouseId) where.warehouseId = warehouseId;
    if (categoryId) where.categoryId = categoryId;
    if (search) {
      where.OR = [
        { sku: { contains: search, mode: "insensitive" } },
        { barcode: { contains: search, mode: "insensitive" } },
        { name: { contains: search, mode: "insensitive" } },
      ];
    }

    // Prisma cannot compare column to column (quantityOnHand <= reorderLevel) directly in where easily without raw SQL,
    // so if lowStock is requested we can filter by condition or do it in service or find items where quantityOnHand <= 20
    const [total, items] = await Promise.all([
      this.prisma.stockItem.count({ where }),
      this.prisma.stockItem.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: "asc" },
        include: {
          category: true,
          warehouse: true,
        },
      }),
    ]);

    const filteredItems = lowStock
      ? items.filter((item) => item.quantityOnHand <= item.reorderLevel)
      : items;

    return {
      items: filteredItems,
      meta: {
        total: lowStock ? filteredItems.length : total,
        page,
        limit,
        totalPages: Math.ceil(
          (lowStock ? filteredItems.length : total) / limit,
        ),
      },
    };
  }

  async updateStockItem(id: string, dto: UpdateStockItemDto) {
    const data: Prisma.StockItemUpdateInput = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.barcode !== undefined) data.barcode = dto.barcode;
    if (dto.unitOfMeasure !== undefined) data.unitOfMeasure = dto.unitOfMeasure;
    if (dto.isActive !== undefined) data.isActive = dto.isActive;
    if (dto.minThreshold !== undefined) data.minThreshold = dto.minThreshold;
    if (dto.maxThreshold !== undefined) data.maxThreshold = dto.maxThreshold;
    if (dto.reorderLevel !== undefined) data.reorderLevel = dto.reorderLevel;
    if (dto.unitPrice !== undefined)
      data.unitPrice = new Prisma.Decimal(dto.unitPrice);
    if (dto.costPrice !== undefined)
      data.costPrice = new Prisma.Decimal(dto.costPrice);
    if (dto.categoryId !== undefined)
      data.category = { connect: { id: dto.categoryId } };
    if (dto.warehouseId !== undefined)
      data.warehouse = { connect: { id: dto.warehouseId } };

    return this.prisma.stockItem.update({
      where: { id },
      data,
      include: { category: true, warehouse: true },
    });
  }

  // ============================================================
  // STOCK MOVEMENTS
  // ============================================================

  async executeStockMovement(
    userId: string,
    dto: CreateStockMovementDto,
    movementNumber: string,
  ) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Calculate increment / decrement
      let qtyDelta = 0;
      if (
        dto.type === StockMovementType.RECEIVE ||
        dto.type === StockMovementType.ADJUST
      ) {
        qtyDelta = dto.quantity;
      } else if (
        dto.type === StockMovementType.ISSUE ||
        dto.type === StockMovementType.TRANSFER
      ) {
        qtyDelta = -dto.quantity;
      }

      // 2. Update StockItem
      const updatedItem = await tx.stockItem.update({
        where: { id: dto.itemId },
        data: {
          quantityOnHand: { increment: qtyDelta },
        },
      });

      // 3. Record movement
      const movement = await tx.stockMovement.create({
        data: {
          movementNumber,
          itemId: dto.itemId,
          warehouseId: dto.warehouseId,
          type: dto.type,
          quantity: dto.quantity,
          referenceType: dto.referenceType,
          referenceId: dto.referenceId,
          reason: dto.reason,
          unitPrice:
            dto.unitPrice !== undefined
              ? new Prisma.Decimal(dto.unitPrice)
              : null,
          createdById: userId,
        },
        include: {
          item: true,
          warehouse: true,
          createdBy: { select: { email: true } },
        },
      });

      return { movement, updatedItem };
    });
  }

  async findMovements(query: QueryStockMovementsDto) {
    const { page = 1, limit = 20, itemId, warehouseId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.StockMovementWhereInput = {};
    if (itemId) where.itemId = itemId;
    if (warehouseId) where.warehouseId = warehouseId;

    const [total, items] = await Promise.all([
      this.prisma.stockMovement.count({ where }),
      this.prisma.stockMovement.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          item: true,
          warehouse: true,
          createdBy: { select: { email: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  // ============================================================
  // STOCK COUNTS
  // ============================================================

  async createStockCount(
    userId: string,
    dto: CreateStockCountDto,
    countNumber: string,
  ) {
    return this.prisma.stockCount.create({
      data: {
        countNumber,
        warehouseId: dto.warehouseId,
        conductedById: userId,
        notes: dto.notes,
      },
      include: {
        warehouse: true,
        conductedBy: { select: { email: true } },
      },
    });
  }

  async findStockCounts(warehouseId?: string) {
    return this.prisma.stockCount.findMany({
      where: warehouseId ? { warehouseId } : undefined,
      orderBy: { countDate: "desc" },
      include: {
        warehouse: true,
        conductedBy: { select: { email: true } },
      },
    });
  }
}
