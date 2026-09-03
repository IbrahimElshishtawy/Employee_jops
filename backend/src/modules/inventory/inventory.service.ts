import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { InventoryRepository } from "./inventory.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
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
import { AuditAction, StockMovementType, NotificationType } from "@prisma/client";

@Injectable()
export class InventoryService {
  private readonly logger = new Logger(InventoryService.name);

  constructor(
    private readonly repo: InventoryRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ============================================================
  // WAREHOUSES
  // ============================================================

  async createWarehouse(userId: string, dto: CreateWarehouseDto) {
    const existing = await this.repo.findWarehouseByCode(dto.code);
    if (existing) {
      throw new ConflictException(`Warehouse with code '${dto.code}' already exists`);
    }

    if (dto.departmentId) {
      const dept = await this.prisma.department.findUnique({ where: { id: dto.departmentId } });
      if (!dept) throw new NotFoundException(`Department '${dto.departmentId}' not found`);
    }

    const warehouse = await this.repo.createWarehouse(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "Warehouse",
        entityId: warehouse.id,
        payload: { code: warehouse.code, name: warehouse.name },
      },
    });

    return warehouse;
  }

  async findWarehouses() {
    return this.repo.findWarehouses();
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  async createCategory(userId: string, dto: CreateStockCategoryDto) {
    const existing = await this.prisma.stockCategory.findUnique({ where: { code: dto.code } });
    if (existing) {
      throw new ConflictException(`Stock category with code '${dto.code}' already exists`);
    }

    const category = await this.repo.createStockCategory(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "StockCategory",
        entityId: category.id,
        payload: { code: category.code, name: category.name },
      },
    });

    return category;
  }

  async findCategories() {
    return this.repo.findStockCategories();
  }

  // ============================================================
  // ITEMS
  // ============================================================

  async createStockItem(userId: string, dto: CreateStockItemDto) {
    const existingSku = await this.repo.findStockItemBySku(dto.sku);
    if (existingSku) {
      throw new ConflictException(`Stock item with SKU '${dto.sku}' already exists`);
    }

    const category = await this.repo.findStockCategoryById(dto.categoryId);
    if (!category) throw new NotFoundException(`Category '${dto.categoryId}' not found`);

    const warehouse = await this.repo.findWarehouseById(dto.warehouseId);
    if (!warehouse) throw new NotFoundException(`Warehouse '${dto.warehouseId}' not found`);

    const item = await this.repo.createStockItem(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "StockItem",
        entityId: item.id,
        payload: { sku: item.sku, name: item.name, warehouseId: item.warehouseId },
      },
    });

    return item;
  }

  async findStockItems(query: QueryStockItemsDto) {
    return this.repo.findStockItems(query);
  }

  async findStockItemById(id: string) {
    const item = await this.repo.findStockItemById(id);
    if (!item) throw new NotFoundException(`Stock item '${id}' not found`);
    return item;
  }

  async updateStockItem(id: string, userId: string, dto: UpdateStockItemDto) {
    await this.findStockItemById(id);
    const updated = await this.repo.updateStockItem(id, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "StockItem",
        entityId: id,
        payload: { changes: dto },
      },
    });

    return updated;
  }

  // ============================================================
  // MOVEMENTS
  // ============================================================

  async executeStockMovement(userId: string, dto: CreateStockMovementDto) {
    const item = await this.findStockItemById(dto.itemId);
    const warehouse = await this.repo.findWarehouseById(dto.warehouseId);
    if (!warehouse) throw new NotFoundException(`Warehouse '${dto.warehouseId}' not found`);

    // Verify sufficient quantity for deduction
    if (
      dto.type === StockMovementType.ISSUE ||
      dto.type === StockMovementType.TRANSFER
    ) {
      if (item.quantityOnHand < dto.quantity) {
        throw new BadRequestException(
          `Insufficient stock for '${item.name}' (SKU: ${item.sku}). Available: ${item.quantityOnHand}, Requested: ${dto.quantity}`,
        );
      }
    }

    const movementNumber = await this.repo.generateMovementNumber();
    const result = await this.repo.executeStockMovement(userId, dto, movementNumber);

    // Check low stock trigger
    if (result.updatedItem.quantityOnHand <= result.updatedItem.reorderLevel) {
      this.logger.warn(
        `Low stock warning: Item '${item.name}' (SKU: ${item.sku}) is at ${result.updatedItem.quantityOnHand} (Reorder level: ${result.updatedItem.reorderLevel})`,
      );
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "StockMovement",
        entityId: result.movement.id,
        payload: {
          movementNumber,
          type: dto.type,
          quantity: dto.quantity,
          remainingQuantity: result.updatedItem.quantityOnHand,
        },
      },
    });

    return result;
  }

  async findMovements(query: QueryStockMovementsDto) {
    return this.repo.findMovements(query);
  }

  // ============================================================
  // STOCK COUNTS
  // ============================================================

  async createStockCount(userId: string, dto: CreateStockCountDto) {
    const warehouse = await this.repo.findWarehouseById(dto.warehouseId);
    if (!warehouse) throw new NotFoundException(`Warehouse '${dto.warehouseId}' not found`);

    const countNumber = await this.repo.generateCountNumber();
    return this.repo.createStockCount(userId, dto, countNumber);
  }

  async findStockCounts(warehouseId?: string) {
    return this.repo.findStockCounts(warehouseId);
  }
}
