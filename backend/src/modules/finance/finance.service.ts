import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { FinanceRepository } from "./finance.repository";
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
import { AuditAction, ExpenseStatus, JournalEntryStatus } from "@prisma/client";

@Injectable()
export class FinanceService {
  private readonly logger = new Logger(FinanceService.name);

  constructor(
    private readonly repo: FinanceRepository,
    private readonly prisma: PrismaService,
  ) {}

  // ============================================================
  // ACCOUNTS
  // ============================================================

  async createAccount(userId: string, dto: CreateChartOfAccountDto) {
    const existing = await this.repo.findAccountByCode(dto.code);
    if (existing) {
      throw new ConflictException(`Chart of account with code '${dto.code}' already exists`);
    }

    if (dto.parentId) {
      const parent = await this.repo.findAccountById(dto.parentId);
      if (!parent) throw new NotFoundException(`Parent account '${dto.parentId}' not found`);
    }

    const account = await this.repo.createAccount(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "ChartOfAccount",
        entityId: account.id,
        payload: { code: account.code, name: account.name, type: account.type },
      },
    });

    return account;
  }

  async findAccounts() {
    return this.repo.findAccounts();
  }

  // ============================================================
  // JOURNAL ENTRIES
  // ============================================================

  async createJournalEntry(userId: string, dto: CreateJournalEntryDto) {
    if (!dto.lines || dto.lines.length < 2) {
      throw new BadRequestException("Journal entry must contain at least two lines for double-entry");
    }

    // Verify all accounts exist
    for (const line of dto.lines) {
      const account = await this.repo.findAccountById(line.accountId);
      if (!account) {
        throw new NotFoundException(`Account '${line.accountId}' not found`);
      }
    }

    // Validate Double-Entry Balancing: sum(debit) == sum(credit)
    const totalDebit = dto.lines.reduce((sum, l) => sum + (l.debit || 0), 0);
    const totalCredit = dto.lines.reduce((sum, l) => sum + (l.credit || 0), 0);

    if (Math.abs(totalDebit - totalCredit) > 0.001) {
      throw new BadRequestException(
        `Double-entry unbalanced: Total Debits (${totalDebit.toFixed(2)}) must equal Total Credits (${totalCredit.toFixed(2)})`,
      );
    }

    const entryNumber = await this.repo.generateEntryNumber();
    const entry = await this.repo.createJournalEntry(userId, dto, entryNumber);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "JournalEntry",
        entityId: entry.id,
        payload: { entryNumber, totalAmount: totalDebit, lineCount: dto.lines.length },
      },
    });

    return entry;
  }

  async findJournalEntries(query: QueryJournalEntriesDto) {
    return this.repo.findJournalEntries(query);
  }

  async findJournalEntryById(id: string) {
    const entry = await this.repo.findJournalEntryById(id);
    if (!entry) throw new NotFoundException(`Journal entry '${id}' not found`);
    return entry;
  }

  async postJournalEntry(id: string, userId: string) {
    const entry = await this.findJournalEntryById(id);
    if (entry.status === JournalEntryStatus.POSTED) {
      throw new BadRequestException(`Journal entry '${id}' is already POSTED`);
    }

    const updated = await this.repo.postJournalEntry(id);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.APPROVE,
        entity: "JournalEntry",
        entityId: id,
        payload: { status: JournalEntryStatus.POSTED },
      },
    });

    return updated;
  }

  // ============================================================
  // EXPENSES
  // ============================================================

  async createExpense(userId: string, dto: CreateExpenseDto) {
    const expenseNumber = await this.repo.generateExpenseNumber();
    const expense = await this.repo.createExpense(userId, dto, expenseNumber);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "FinancialExpense",
        entityId: expense.id,
        payload: { expenseNumber, amount: dto.amount, category: dto.category },
      },
    });

    return expense;
  }

  async findExpenses(query: QueryExpensesDto) {
    return this.repo.findExpenses(query);
  }

  async updateExpenseStatus(id: string, userId: string, status: ExpenseStatus) {
    const updated = await this.repo.updateExpenseStatus(id, status);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "FinancialExpense",
        entityId: id,
        payload: { status },
      },
    });

    return updated;
  }

  // ============================================================
  // REVENUES
  // ============================================================

  async createRevenue(userId: string, dto: CreateRevenueDto) {
    const receiptNumber = await this.repo.generateReceiptNumber();
    const revenue = await this.repo.createRevenue(userId, dto, receiptNumber);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "FinancialRevenue",
        entityId: revenue.id,
        payload: { receiptNumber, amount: dto.amount, category: dto.category },
      },
    });

    return revenue;
  }

  async findRevenues(query: QueryRevenuesDto) {
    return this.repo.findRevenues(query);
  }

  // ============================================================
  // BANK ACCOUNTS
  // ============================================================

  async createBankAccount(userId: string, dto: CreateBankAccountDto) {
    const existing = await this.repo.findBankAccountByNumber(dto.accountNumber);
    if (existing) {
      throw new ConflictException(`Bank account with number '${dto.accountNumber}' already exists`);
    }

    const bankAccount = await this.repo.createBankAccount(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "BankAccount",
        entityId: bankAccount.id,
        payload: { bankName: bankAccount.bankName, accountNumber: bankAccount.accountNumber },
      },
    });

    return bankAccount;
  }

  async findBankAccounts() {
    return this.repo.findBankAccounts();
  }
}
