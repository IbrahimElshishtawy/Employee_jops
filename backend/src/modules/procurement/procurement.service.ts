import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { ProcurementRepository } from "./procurement.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
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
import {
  AuditAction,
  PurchaseRequestStatus,
  PurchaseOrderStatus,
  UserStatus,
  NotificationType,
} from "@prisma/client";

@Injectable()
export class ProcurementService {
  private readonly logger = new Logger(ProcurementService.name);

  constructor(
    private readonly repo: ProcurementRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ============================================================
  // SUPPLIERS
  // ============================================================

  async createSupplier(userId: string, dto: CreateSupplierDto) {
    const existing = await this.repo.findSupplierByCode(dto.code);
    if (existing) {
      throw new ConflictException(
        `Supplier with code '${dto.code}' already exists`,
      );
    }

    const supplier = await this.repo.createSupplier(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "Supplier",
        entityId: supplier.id,
        payload: { code: supplier.code, name: supplier.name },
      },
    });

    return supplier;
  }

  async findSuppliers(query: QuerySuppliersDto) {
    return this.repo.findSuppliers(query);
  }

  async findSupplierById(id: string) {
    const supplier = await this.repo.findSupplierById(id);
    if (!supplier) throw new NotFoundException(`Supplier '${id}' not found`);
    return supplier;
  }

  async updateSupplier(id: string, userId: string, dto: UpdateSupplierDto) {
    await this.findSupplierById(id);
    const updated = await this.repo.updateSupplier(id, dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "Supplier",
        entityId: id,
        payload: { changes: JSON.parse(JSON.stringify(dto)) },
      },
    });

    return updated;
  }

  // ============================================================
  // PURCHASE REQUESTS
  // ============================================================

  async createPurchaseRequest(userId: string, dto: CreatePurchaseRequestDto) {
    const requester = await this.prisma.employeeProfile.findUnique({
      where: { userId },
      include: { user: true },
    });

    if (!requester || requester.user?.status !== UserStatus.ACTIVE) {
      throw new BadRequestException(
        "Active employee profile required to create purchase requests",
      );
    }

    const department = await this.prisma.department.findUnique({
      where: { id: dto.departmentId },
    });
    if (!department)
      throw new NotFoundException(`Department '${dto.departmentId}' not found`);

    if (!dto.items || dto.items.length === 0) {
      throw new BadRequestException(
        "Purchase request must contain at least one line item",
      );
    }

    const totalEstimatedCost = dto.items.reduce(
      (sum, item) => sum + item.estimatedUnitPrice * item.quantity,
      0,
    );

    const requestNumber = await this.repo.generatePRNumber();
    const pr = await this.repo.createPurchaseRequest(
      requester.id,
      dto,
      requestNumber,
      totalEstimatedCost,
    );

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "PurchaseRequest",
        entityId: pr.id,
        payload: {
          requestNumber,
          totalEstimatedCost,
          itemCount: dto.items.length,
        },
      },
    });

    return pr;
  }

  async findPurchaseRequests(query: QueryPurchaseRequestsDto) {
    return this.repo.findPurchaseRequests(query);
  }

  async findPurchaseRequestById(id: string) {
    const pr = await this.repo.findPurchaseRequestById(id);
    if (!pr) throw new NotFoundException(`Purchase request '${id}' not found`);
    return pr;
  }

  async approvePurchaseRequest(id: string, userId: string) {
    await this.findPurchaseRequestById(id);
    const updated = await this.repo.updatePurchaseRequestStatus(
      id,
      PurchaseRequestStatus.APPROVED,
    );

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.APPROVE,
        entity: "PurchaseRequest",
        entityId: id,
        payload: { status: PurchaseRequestStatus.APPROVED },
      },
    });

    return updated;
  }

  // ============================================================
  // PURCHASE ORDERS
  // ============================================================

  async createPurchaseOrder(userId: string, dto: CreatePurchaseOrderDto) {
    const supplier = await this.repo.findSupplierById(dto.supplierId);
    if (!supplier)
      throw new NotFoundException(`Supplier '${dto.supplierId}' not found`);

    if (dto.purchaseRequestId) {
      const pr = await this.repo.findPurchaseRequestById(dto.purchaseRequestId);
      if (!pr)
        throw new NotFoundException(
          `Purchase request '${dto.purchaseRequestId}' not found`,
        );
    }

    if (!dto.items || dto.items.length === 0) {
      throw new BadRequestException(
        "Purchase order must contain at least one line item",
      );
    }

    const subtotal = dto.items.reduce(
      (sum, item) => sum + item.unitPrice * item.quantityOrdered,
      0,
    );
    const taxAmount = dto.taxAmount || 0;
    const totalAmount = subtotal + taxAmount;

    const orderNumber = await this.repo.generatePONumber();
    const po = await this.repo.createPurchaseOrder(
      dto,
      orderNumber,
      subtotal,
      taxAmount,
      totalAmount,
    );

    // If linked to a PR, mark PR as ORDERED
    if (dto.purchaseRequestId) {
      await this.repo.updatePurchaseRequestStatus(
        dto.purchaseRequestId,
        PurchaseRequestStatus.ORDERED,
      );
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "PurchaseOrder",
        entityId: po.id,
        payload: { orderNumber, totalAmount, supplierId: dto.supplierId },
      },
    });

    return po;
  }

  async findPurchaseOrders(query: QueryPurchaseOrdersDto) {
    return this.repo.findPurchaseOrders(query);
  }

  async findPurchaseOrderById(id: string) {
    const po = await this.repo.findPurchaseOrderById(id);
    if (!po) throw new NotFoundException(`Purchase order '${id}' not found`);
    return po;
  }

  async updatePurchaseOrderStatus(
    id: string,
    userId: string,
    status: PurchaseOrderStatus,
  ) {
    await this.findPurchaseOrderById(id);
    const updated = await this.repo.updatePurchaseOrderStatus(id, status);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "PurchaseOrder",
        entityId: id,
        payload: { status },
      },
    });

    return updated;
  }

  // ============================================================
  // SUPPLIER INVOICES
  // ============================================================

  async createSupplierInvoice(userId: string, dto: CreateSupplierInvoiceDto) {
    const existing = await this.prisma.supplierInvoice.findUnique({
      where: { invoiceNumber: dto.invoiceNumber },
    });
    if (existing) {
      throw new ConflictException(
        `Invoice with number '${dto.invoiceNumber}' already exists`,
      );
    }

    const supplier = await this.repo.findSupplierById(dto.supplierId);
    if (!supplier)
      throw new NotFoundException(`Supplier '${dto.supplierId}' not found`);

    if (dto.purchaseOrderId) {
      const po = await this.repo.findPurchaseOrderById(dto.purchaseOrderId);
      if (!po)
        throw new NotFoundException(
          `Purchase order '${dto.purchaseOrderId}' not found`,
        );
    }

    const totalAmount = dto.subtotal + (dto.taxAmount || 0);
    const invoice = await this.repo.createSupplierInvoice(dto, totalAmount);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "SupplierInvoice",
        entityId: invoice.id,
        payload: { invoiceNumber: invoice.invoiceNumber, totalAmount },
      },
    });

    return invoice;
  }

  async findSupplierInvoices(query: QuerySupplierInvoicesDto) {
    return this.repo.findSupplierInvoices(query);
  }

  async findSupplierInvoiceById(id: string) {
    const invoice = await this.repo.findSupplierInvoiceById(id);
    if (!invoice)
      throw new NotFoundException(`Supplier invoice '${id}' not found`);
    return invoice;
  }
}
