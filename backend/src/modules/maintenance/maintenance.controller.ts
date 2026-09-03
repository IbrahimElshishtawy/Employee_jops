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
import { MaintenanceService } from "./maintenance.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
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

@ApiTags("Maintenance Management")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("maintenance")
export class MaintenanceController {
  constructor(private readonly maintenanceService: MaintenanceService) {}

  // Requests
  @Post("requests")
  @ApiOperation({ summary: "Create a maintenance request" })
  @ApiResponse({ status: 201, description: "Request created" })
  createRequest(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateMaintenanceRequestDto,
  ) {
    return this.maintenanceService.createRequest(userId, dto);
  }

  @Get("requests")
  @ApiOperation({
    summary: "List maintenance requests with pagination and filters",
  })
  findRequests(@Query() query: QueryMaintenanceRequestsDto) {
    return this.maintenanceService.findRequests(query);
  }

  @Get("requests/:id")
  @ApiOperation({ summary: "Get maintenance request details" })
  findRequestById(@Param("id") id: string) {
    return this.maintenanceService.findRequestById(id);
  }

  @Patch("requests/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Update maintenance request status or resolution" })
  updateRequest(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateMaintenanceRequestDto,
  ) {
    return this.maintenanceService.updateRequest(id, userId, dto);
  }

  // Work Orders
  @Post("work-orders")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Create a maintenance work order" })
  @ApiResponse({ status: 201, description: "Work order created" })
  createWorkOrder(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateWorkOrderDto,
  ) {
    return this.maintenanceService.createWorkOrder(userId, dto);
  }

  @Get("work-orders")
  @ApiOperation({ summary: "List work orders with pagination and filters" })
  findWorkOrders(@Query() query: QueryWorkOrdersDto) {
    return this.maintenanceService.findWorkOrders(query);
  }

  @Get("work-orders/:id")
  @ApiOperation({
    summary: "Get work order details including spare parts and technicians",
  })
  findWorkOrderById(@Param("id") id: string) {
    return this.maintenanceService.findWorkOrderById(id);
  }

  @Patch("work-orders/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Update work order status, technician, or hours" })
  updateWorkOrder(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateWorkOrderDto,
  ) {
    return this.maintenanceService.updateWorkOrder(id, userId, dto);
  }

  @Post("work-orders/:id/spare-parts")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary: "Consume spare parts on a work order and decrement inventory",
  })
  consumeSparePart(
    @Param("id") workOrderId: string,
    @CurrentUser("id") userId: string,
    @Body() dto: ConsumeSparePartDto,
  ) {
    return this.maintenanceService.consumeSparePart(workOrderId, userId, dto);
  }

  // Spare Parts Catalog
  @Post("spare-parts")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Register a new spare part in catalog" })
  createSparePart(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateSparePartDto,
  ) {
    return this.maintenanceService.createSparePart(userId, dto);
  }

  @Get("spare-parts")
  @ApiOperation({ summary: "List all spare parts catalog" })
  findSpareParts() {
    return this.maintenanceService.findSpareParts();
  }
}
