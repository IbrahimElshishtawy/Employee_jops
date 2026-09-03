import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from "@nestjs/swagger";
import { InventoryService } from "./inventory.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
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

@ApiTags("Inventory & Stores")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("inventory")
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  // Warehouses
  @Post("warehouses")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Create a new warehouse or storage location" })
  createWarehouse(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateWarehouseDto,
  ) {
    return this.inventoryService.createWarehouse(userId, dto);
  }

  @Get("warehouses")
  @ApiOperation({ summary: "List all warehouses" })
  findWarehouses() {
    return this.inventoryService.findWarehouses();
  }

  // Categories
  @Post("categories")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Create a stock category" })
  createCategory(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateStockCategoryDto,
  ) {
    return this.inventoryService.createCategory(userId, dto);
  }

  @Get("categories")
  @ApiOperation({ summary: "List stock categories" })
  findCategories() {
    return this.inventoryService.findCategories();
  }

  // Items
  @Post("items")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary:
      "Create a new stock item with SKU, thresholds, and initial balance",
  })
  createStockItem(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateStockItemDto,
  ) {
    return this.inventoryService.createStockItem(userId, dto);
  }

  @Get("items")
  @ApiOperation({
    summary:
      "List stock items with search, warehouse filter, and low-stock indicator",
  })
  findStockItems(@Query() query: QueryStockItemsDto) {
    return this.inventoryService.findStockItems(query);
  }

  @Get("items/:id")
  @ApiOperation({ summary: "Get stock item details" })
  findStockItemById(@Param("id") id: string) {
    return this.inventoryService.findStockItemById(id);
  }

  @Patch("items/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "Update stock item metadata, thresholds, or pricing",
  })
  updateStockItem(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateStockItemDto,
  ) {
    return this.inventoryService.updateStockItem(id, userId, dto);
  }

  // Movements
  @Post("movements")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "Execute a stock movement (RECEIVE, ISSUE, TRANSFER, ADJUST)",
  })
  executeStockMovement(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateStockMovementDto,
  ) {
    return this.inventoryService.executeStockMovement(userId, dto);
  }

  @Get("movements")
  @ApiOperation({ summary: "List stock movement history with filters" })
  findMovements(@Query() query: QueryStockMovementsDto) {
    return this.inventoryService.findMovements(query);
  }

  // Physical Counts
  @Post("counts")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "Initiate a physical inventory count audit session",
  })
  createStockCount(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateStockCountDto,
  ) {
    return this.inventoryService.createStockCount(userId, dto);
  }

  @Get("counts")
  @ApiOperation({ summary: "List stock count audit sessions" })
  findStockCounts(@Query("warehouseId") warehouseId?: string) {
    return this.inventoryService.findStockCounts(warehouseId);
  }
}
