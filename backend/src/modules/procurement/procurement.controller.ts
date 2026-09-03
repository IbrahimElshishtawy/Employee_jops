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
import { ProcurementService } from "./procurement.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role, PurchaseOrderStatus } from "@prisma/client";
import {
  CreateSupplierDto,
  UpdateSupplierDto,
  CreatePurchaseRequestDto,
  CreatePurchaseOrderDto,
  CreateSupplierInvoiceDto,
  QuerySuppliersDto,
  QueryPurchaseRequestsDto,
  QueryPurchaseOrdersDto,
  QuerySupplierInvoicesDto,
} from "./dto";

@ApiTags("Procurement & Suppliers")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("procurement")
export class ProcurementController {
  constructor(private readonly procurementService: ProcurementService) {}

  // Suppliers
  @Post("suppliers")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Register a new supplier" })
  createSupplier(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateSupplierDto,
  ) {
    return this.procurementService.createSupplier(userId, dto);
  }

  @Get("suppliers")
  @ApiOperation({ summary: "List suppliers with search and pagination" })
  findSuppliers(@Query() query: QuerySuppliersDto) {
    return this.procurementService.findSuppliers(query);
  }

  @Get("suppliers/:id")
  @ApiOperation({ summary: "Get supplier details by ID" })
  findSupplierById(@Param("id") id: string) {
    return this.procurementService.findSupplierById(id);
  }

  @Patch("suppliers/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Update supplier details or rating" })
  updateSupplier(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateSupplierDto,
  ) {
    return this.procurementService.updateSupplier(id, userId, dto);
  }

  // Purchase Requests
  @Post("requests")
  @ApiOperation({ summary: "Create a purchase request (PR)" })
  createPurchaseRequest(
    @CurrentUser("id") userId: string,
    @Body() dto: CreatePurchaseRequestDto,
  ) {
    return this.procurementService.createPurchaseRequest(userId, dto);
  }

  @Get("requests")
  @ApiOperation({ summary: "List purchase requests with filters" })
  findPurchaseRequests(@Query() query: QueryPurchaseRequestsDto) {
    return this.procurementService.findPurchaseRequests(query);
  }

  @Get("requests/:id")
  @ApiOperation({ summary: "Get purchase request details" })
  findPurchaseRequestById(@Param("id") id: string) {
    return this.procurementService.findPurchaseRequestById(id);
  }

  @Post("requests/:id/approve")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Approve a purchase request" })
  approvePurchaseRequest(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.procurementService.approvePurchaseRequest(id, userId);
  }

  // Purchase Orders
  @Post("orders")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Create a purchase order (PO) from scratch or from approved PR" })
  createPurchaseOrder(
    @CurrentUser("id") userId: string,
    @Body() dto: CreatePurchaseOrderDto,
  ) {
    return this.procurementService.createPurchaseOrder(userId, dto);
  }

  @Get("orders")
  @ApiOperation({ summary: "List purchase orders with filters" })
  findPurchaseOrders(@Query() query: QueryPurchaseOrdersDto) {
    return this.procurementService.findPurchaseOrders(query);
  }

  @Get("orders/:id")
  @ApiOperation({ summary: "Get purchase order details and items" })
  findPurchaseOrderById(@Param("id") id: string) {
    return this.procurementService.findPurchaseOrderById(id);
  }

  @Patch("orders/:id/status")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Update purchase order status (SENT, PARTIALLY_RECEIVED, RECEIVED, etc.)" })
  updatePurchaseOrderStatus(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body("status") status: PurchaseOrderStatus,
  ) {
    return this.procurementService.updatePurchaseOrderStatus(id, userId, status);
  }

  // Supplier Invoices
  @Post("invoices")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Register a supplier invoice matched with PO" })
  createSupplierInvoice(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateSupplierInvoiceDto,
  ) {
    return this.procurementService.createSupplierInvoice(userId, dto);
  }

  @Get("invoices")
  @ApiOperation({ summary: "List supplier invoices with status filters" })
  findSupplierInvoices(@Query() query: QuerySupplierInvoicesDto) {
    return this.procurementService.findSupplierInvoices(query);
  }

  @Get("invoices/:id")
  @ApiOperation({ summary: "Get supplier invoice details" })
  findSupplierInvoiceById(@Param("id") id: string) {
    return this.procurementService.findSupplierInvoiceById(id);
  }
}
