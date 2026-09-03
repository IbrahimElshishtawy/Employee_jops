import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
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
  Prisma,
  PurchaseRequestStatus,
  PurchaseOrderStatus,
  SupplierInvoiceStatus,
} from "@prisma/client";

@Injectable()
export class ProcurementRepository {
  constructor(private readonly prisma: PrismaService) {}

  async generatePRNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.purchaseRequest.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `PR-${today}-${seq}`;
  }

  async generatePONumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.purchaseOrder.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `PO-${today}-${seq}`;
  }

  // ============================================================
  // SUPPLIERS
  // ============================================================

  async createSupplier(dto: CreateSupplierDto) {
    return this.prisma.supplier.create({
      data: {
        code: dto.code,
        name: dto.name,
        contactPerson: dto.contactPerson,
        email: dto.email,
        phone: dto.phone,
        address: dto.address,
        taxNumber: dto.taxNumber,
        paymentTerms: dto.paymentTerms,
        rating:
          dto.rating !== undefined
            ? new Prisma.Decimal(dto.rating)
            : new Prisma.Decimal(5.0),
      },
    });
  }

  async findSuppliers(query: QuerySuppliersDto) {
    const { page = 1, limit = 20, search } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.SupplierWhereInput = {};
    if (search) {
      where.OR = [
        { name: { contains: search, mode: "insensitive" } },
        { code: { contains: search, mode: "insensitive" } },
        { contactPerson: { contains: search, mode: "insensitive" } },
        { email: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.supplier.count({ where }),
      this.prisma.supplier.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: "asc" },
        include: {
          _count: { select: { purchaseOrders: true, invoices: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findSupplierById(id: string) {
    return this.prisma.supplier.findUnique({
      where: { id },
      include: {
        purchaseOrders: { take: 5, orderBy: { createdAt: "desc" } },
        invoices: { take: 5, orderBy: { createdAt: "desc" } },
      },
    });
  }

  async findSupplierByCode(code: string) {
    return this.prisma.supplier.findUnique({
      where: { code },
    });
  }

  async updateSupplier(id: string, dto: UpdateSupplierDto) {
    const data: Prisma.SupplierUpdateInput = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.contactPerson !== undefined) data.contactPerson = dto.contactPerson;
    if (dto.email !== undefined) data.email = dto.email;
    if (dto.phone !== undefined) data.phone = dto.phone;
    if (dto.address !== undefined) data.address = dto.address;
    if (dto.taxNumber !== undefined) data.taxNumber = dto.taxNumber;
    if (dto.paymentTerms !== undefined) data.paymentTerms = dto.paymentTerms;
    if (dto.rating !== undefined) data.rating = new Prisma.Decimal(dto.rating);

    return this.prisma.supplier.update({
      where: { id },
      data,
    });
  }

  // ============================================================
  // PURCHASE REQUESTS
  // ============================================================

  async createPurchaseRequest(
    requesterProfileId: string,
    dto: CreatePurchaseRequestDto,
    requestNumber: string,
    totalEstimatedCost: number,
  ) {
    return this.prisma.purchaseRequest.create({
      data: {
        requestNumber,
        departmentId: dto.departmentId,
        requesterId: requesterProfileId,
        priority: dto.priority || "MEDIUM",
        status: PurchaseRequestStatus.DRAFT,
        requiredDate: dto.requiredDate ? new Date(dto.requiredDate) : null,
        notes: dto.notes,
        totalEstimatedCost: new Prisma.Decimal(totalEstimatedCost),
        items: {
          create: dto.items.map((item) => ({
            itemId: item.itemId,
            itemName: item.itemName,
            description: item.description,
            quantity: item.quantity,
            unitOfMeasure: item.unitOfMeasure || "PCS",
            estimatedUnitPrice: new Prisma.Decimal(item.estimatedUnitPrice),
            totalPrice: new Prisma.Decimal(
              item.estimatedUnitPrice * item.quantity,
            ),
          })),
        },
      },
      include: {
        department: true,
        requester: {
          include: { user: { select: { email: true } } },
        },
        items: true,
      },
    });
  }

  async findPurchaseRequests(query: QueryPurchaseRequestsDto) {
    const { page = 1, limit = 20, status, departmentId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.PurchaseRequestWhereInput = {};
    if (status) where.status = status;
    if (departmentId) where.departmentId = departmentId;

    const [total, items] = await Promise.all([
      this.prisma.purchaseRequest.count({ where }),
      this.prisma.purchaseRequest.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          department: true,
          requester: { select: { firstName: true, lastName: true } },
          _count: { select: { items: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findPurchaseRequestById(id: string) {
    return this.prisma.purchaseRequest.findUnique({
      where: { id },
      include: {
        department: true,
        requester: {
          include: { user: { select: { email: true } } },
        },
        items: {
          include: { item: true },
        },
        purchaseOrders: true,
      },
    });
  }

  async updatePurchaseRequestStatus(id: string, status: PurchaseRequestStatus) {
    return this.prisma.purchaseRequest.update({
      where: { id },
      data: { status },
      include: { department: true, requester: true },
    });
  }

  // ============================================================
  // PURCHASE ORDERS
  // ============================================================

  async createPurchaseOrder(
    dto: CreatePurchaseOrderDto,
    orderNumber: string,
    subtotal: number,
    taxAmount: number,
    totalAmount: number,
  ) {
    return this.prisma.purchaseOrder.create({
      data: {
        orderNumber,
        purchaseRequestId: dto.purchaseRequestId,
        supplierId: dto.supplierId,
        expectedDeliveryDate: dto.expectedDeliveryDate
          ? new Date(dto.expectedDeliveryDate)
          : null,
        paymentTerms: dto.paymentTerms,
        subtotal: new Prisma.Decimal(subtotal),
        taxAmount: new Prisma.Decimal(taxAmount),
        totalAmount: new Prisma.Decimal(totalAmount),
        notes: dto.notes,
        status: PurchaseOrderStatus.DRAFT,
        items: {
          create: dto.items.map((item) => ({
            itemId: item.itemId,
            itemName: item.itemName,
            quantityOrdered: item.quantityOrdered,
            quantityReceived: 0,
            unitPrice: new Prisma.Decimal(item.unitPrice),
            totalPrice: new Prisma.Decimal(
              item.unitPrice * item.quantityOrdered,
            ),
          })),
        },
      },
      include: {
        supplier: true,
        purchaseRequest: true,
        items: true,
      },
    });
  }

  async findPurchaseOrders(query: QueryPurchaseOrdersDto) {
    const { page = 1, limit = 20, status, supplierId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.PurchaseOrderWhereInput = {};
    if (status) where.status = status;
    if (supplierId) where.supplierId = supplierId;

    const [total, items] = await Promise.all([
      this.prisma.purchaseOrder.count({ where }),
      this.prisma.purchaseOrder.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          supplier: true,
          _count: { select: { items: true, invoices: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findPurchaseOrderById(id: string) {
    return this.prisma.purchaseOrder.findUnique({
      where: { id },
      include: {
        supplier: true,
        purchaseRequest: true,
        items: {
          include: { item: true },
        },
        invoices: true,
      },
    });
  }

  async updatePurchaseOrderStatus(id: string, status: PurchaseOrderStatus) {
    return this.prisma.purchaseOrder.update({
      where: { id },
      data: { status },
      include: { supplier: true },
    });
  }

  // ============================================================
  // SUPPLIER INVOICES
  // ============================================================

  async createSupplierInvoice(
    dto: CreateSupplierInvoiceDto,
    totalAmount: number,
  ) {
    return this.prisma.supplierInvoice.create({
      data: {
        invoiceNumber: dto.invoiceNumber,
        purchaseOrderId: dto.purchaseOrderId,
        supplierId: dto.supplierId,
        invoiceDate: dto.invoiceDate ? new Date(dto.invoiceDate) : new Date(),
        dueDate: new Date(dto.dueDate),
        subtotal: new Prisma.Decimal(dto.subtotal),
        taxAmount: new Prisma.Decimal(dto.taxAmount || 0),
        totalAmount: new Prisma.Decimal(totalAmount),
        paidAmount: new Prisma.Decimal(0),
        status: SupplierInvoiceStatus.UNPAID,
        notes: dto.notes,
      },
      include: {
        supplier: true,
        purchaseOrder: true,
      },
    });
  }

  async findSupplierInvoices(query: QuerySupplierInvoicesDto) {
    const { page = 1, limit = 20, status, supplierId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.SupplierInvoiceWhereInput = {};
    if (status) where.status = status;
    if (supplierId) where.supplierId = supplierId;

    const [total, items] = await Promise.all([
      this.prisma.supplierInvoice.count({ where }),
      this.prisma.supplierInvoice.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          supplier: true,
          purchaseOrder: { select: { orderNumber: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findSupplierInvoiceById(id: string) {
    return this.prisma.supplierInvoice.findUnique({
      where: { id },
      include: {
        supplier: true,
        purchaseOrder: {
          include: { items: true },
        },
      },
    });
  }

  async recordInvoicePayment(invoiceId: string, amount: number) {
    const invoice = await this.prisma.supplierInvoice.findUnique({
      where: { id: invoiceId },
    });
    if (!invoice) return null;

    const newPaid = Number(invoice.paidAmount) + amount;
    const total = Number(invoice.totalAmount);
    let newStatus = invoice.status;

    if (newPaid >= total) {
      newStatus = SupplierInvoiceStatus.PAID;
    } else if (newPaid > 0) {
      newStatus = SupplierInvoiceStatus.PARTIALLY_PAID;
    }

    return this.prisma.supplierInvoice.update({
      where: { id: invoiceId },
      data: {
        paidAmount: new Prisma.Decimal(newPaid),
        status: newStatus,
      },
    });
  }
}
