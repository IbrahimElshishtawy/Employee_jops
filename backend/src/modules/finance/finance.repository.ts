import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  CreateChartOfAccountDto,
  CreateJournalEntryDto,
  CreateExpenseDto,
  CreateRevenueDto,
  CreateBankAccountDto,
  QueryJournalEntriesDto,
  QueryExpensesDto,
  QueryRevenuesDto,
} from "./dto";
import { Prisma, JournalEntryStatus, ExpenseStatus } from "@prisma/client";

@Injectable()
export class FinanceRepository {
  constructor(private readonly prisma: PrismaService) {}

  async generateEntryNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.journalEntry.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `JE-${today}-${seq}`;
  }

  async generateExpenseNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.financialExpense.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `EXP-${today}-${seq}`;
  }

  async generateReceiptNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.financialRevenue.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `REV-${today}-${seq}`;
  }

  // ============================================================
  // CHART OF ACCOUNTS
  // ============================================================

  async createAccount(dto: CreateChartOfAccountDto) {
    return this.prisma.chartOfAccount.create({
      data: {
        code: dto.code,
        name: dto.name,
        type: dto.type,
        category: dto.category,
        parentId: dto.parentId,
        isHeader: dto.isHeader || false,
      },
    });
  }

  async findAccounts() {
    return this.prisma.chartOfAccount.findMany({
      orderBy: { code: "asc" },
      include: {
        children: true,
      },
    });
  }

  async findAccountById(id: string) {
    return this.prisma.chartOfAccount.findUnique({
      where: { id },
      include: { children: true, parent: true },
    });
  }

  async findAccountByCode(code: string) {
    return this.prisma.chartOfAccount.findUnique({
      where: { code },
    });
  }

  // ============================================================
  // JOURNAL ENTRIES
  // ============================================================

  async createJournalEntry(
    userId: string,
    dto: CreateJournalEntryDto,
    entryNumber: string,
  ) {
    return this.prisma.journalEntry.create({
      data: {
        entryNumber,
        entryDate: dto.entryDate ? new Date(dto.entryDate) : new Date(),
        reference: dto.reference,
        memo: dto.memo,
        status: JournalEntryStatus.DRAFT,
        createdById: userId,
        lines: {
          create: dto.lines.map((line) => ({
            accountId: line.accountId,
            debit: new Prisma.Decimal(line.debit || 0),
            credit: new Prisma.Decimal(line.credit || 0),
            description: line.description,
            departmentId: line.departmentId,
          })),
        },
      },
      include: {
        lines: {
          include: { account: true },
        },
        createdBy: { select: { email: true } },
      },
    });
  }

  async findJournalEntries(query: QueryJournalEntriesDto) {
    const { page = 1, limit = 20, status, search } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.JournalEntryWhereInput = {};
    if (status) where.status = status;
    if (search) {
      where.OR = [
        { entryNumber: { contains: search, mode: "insensitive" } },
        { reference: { contains: search, mode: "insensitive" } },
        { memo: { contains: search, mode: "insensitive" } },
      ];
    }

    const [total, items] = await Promise.all([
      this.prisma.journalEntry.count({ where }),
      this.prisma.journalEntry.findMany({
        where,
        skip,
        take: limit,
        orderBy: { entryDate: "desc" },
        include: {
          lines: {
            include: { account: true },
          },
          createdBy: { select: { email: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findJournalEntryById(id: string) {
    return this.prisma.journalEntry.findUnique({
      where: { id },
      include: {
        lines: {
          include: { account: true },
        },
        createdBy: { select: { email: true } },
      },
    });
  }

  async postJournalEntry(id: string) {
    return this.prisma.journalEntry.update({
      where: { id },
      data: { status: JournalEntryStatus.POSTED },
      include: { lines: { include: { account: true } } },
    });
  }

  // ============================================================
  // EXPENSES
  // ============================================================

  async createExpense(
    userId: string,
    dto: CreateExpenseDto,
    expenseNumber: string,
  ) {
    return this.prisma.financialExpense.create({
      data: {
        expenseNumber,
        category: dto.category,
        amount: new Prisma.Decimal(dto.amount),
        currency: dto.currency || "SAR",
        expenseDate: dto.expenseDate ? new Date(dto.expenseDate) : new Date(),
        status: ExpenseStatus.PENDING,
        departmentId: dto.departmentId,
        paidTo: dto.paidTo,
        paymentMethod: dto.paymentMethod || "BANK_TRANSFER",
        reference: dto.reference,
        description: dto.description,
        createdById: userId,
      },
      include: {
        createdBy: { select: { email: true } },
      },
    });
  }

  async findExpenses(query: QueryExpensesDto) {
    const { page = 1, limit = 20, status, category, departmentId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.FinancialExpenseWhereInput = {};
    if (status) where.status = status;
    if (category) where.category = category;
    if (departmentId) where.departmentId = departmentId;

    const [total, items] = await Promise.all([
      this.prisma.financialExpense.count({ where }),
      this.prisma.financialExpense.findMany({
        where,
        skip,
        take: limit,
        orderBy: { expenseDate: "desc" },
        include: {
          createdBy: { select: { email: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async updateExpenseStatus(id: string, status: ExpenseStatus) {
    return this.prisma.financialExpense.update({
      where: { id },
      data: { status },
    });
  }

  // ============================================================
  // REVENUES
  // ============================================================

  async createRevenue(
    userId: string,
    dto: CreateRevenueDto,
    receiptNumber: string,
  ) {
    return this.prisma.financialRevenue.create({
      data: {
        receiptNumber,
        category: dto.category,
        amount: new Prisma.Decimal(dto.amount),
        currency: dto.currency || "SAR",
        revenueDate: dto.revenueDate ? new Date(dto.revenueDate) : new Date(),
        departmentId: dto.departmentId,
        receivedFrom: dto.receivedFrom,
        paymentMethod: dto.paymentMethod || "BANK_TRANSFER",
        reference: dto.reference,
        description: dto.description,
        createdById: userId,
      },
      include: {
        createdBy: { select: { email: true } },
      },
    });
  }

  async findRevenues(query: QueryRevenuesDto) {
    const { page = 1, limit = 20, category, departmentId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.FinancialRevenueWhereInput = {};
    if (category) where.category = category;
    if (departmentId) where.departmentId = departmentId;

    const [total, items] = await Promise.all([
      this.prisma.financialRevenue.count({ where }),
      this.prisma.financialRevenue.findMany({
        where,
        skip,
        take: limit,
        orderBy: { revenueDate: "desc" },
        include: {
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
  // BANK ACCOUNTS
  // ============================================================

  async createBankAccount(dto: CreateBankAccountDto) {
    return this.prisma.bankAccount.create({
      data: {
        bankName: dto.bankName,
        accountNumber: dto.accountNumber,
        iban: dto.iban,
        branchName: dto.branchName,
        currency: dto.currency || "SAR",
        openingBalance: new Prisma.Decimal(dto.openingBalance || 0),
        currentBalance: new Prisma.Decimal(dto.openingBalance || 0),
      },
    });
  }

  async findBankAccounts() {
    return this.prisma.bankAccount.findMany({
      where: { isActive: true },
      orderBy: { bankName: "asc" },
    });
  }

  async findBankAccountById(id: string) {
    return this.prisma.bankAccount.findUnique({
      where: { id },
    });
  }

  async findBankAccountByNumber(accountNumber: string) {
    return this.prisma.bankAccount.findUnique({
      where: { accountNumber },
    });
  }
}
