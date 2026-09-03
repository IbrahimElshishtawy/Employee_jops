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
import { FinanceService } from "./finance.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role, ExpenseStatus } from "@prisma/client";
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

@ApiTags("Finance & Accounting")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("finance")
export class FinanceController {
  constructor(private readonly financeService: FinanceService) {}

  // Chart of Accounts
  @Post("accounts")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Create a chart of accounts entry" })
  createAccount(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateChartOfAccountDto,
  ) {
    return this.financeService.createAccount(userId, dto);
  }

  @Get("accounts")
  @ApiOperation({ summary: "Get chart of accounts tree" })
  findAccounts() {
    return this.financeService.findAccounts();
  }

  // Journal Entries
  @Post("journal-entries")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Create a balanced double-entry journal entry" })
  createJournalEntry(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateJournalEntryDto,
  ) {
    return this.financeService.createJournalEntry(userId, dto);
  }

  @Get("journal-entries")
  @ApiOperation({ summary: "List journal entries with pagination and filters" })
  findJournalEntries(@Query() query: QueryJournalEntriesDto) {
    return this.financeService.findJournalEntries(query);
  }

  @Get("journal-entries/:id")
  @ApiOperation({ summary: "Get journal entry details including debit/credit lines" })
  findJournalEntryById(@Param("id") id: string) {
    return this.financeService.findJournalEntryById(id);
  }

  @Post("journal-entries/:id/post")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Post a journal entry to the general ledger" })
  postJournalEntry(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.financeService.postJournalEntry(id, userId);
  }

  // Expenses
  @Post("expenses")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Record a financial expense" })
  createExpense(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateExpenseDto,
  ) {
    return this.financeService.createExpense(userId, dto);
  }

  @Get("expenses")
  @ApiOperation({ summary: "List financial expenses with filters" })
  findExpenses(@Query() query: QueryExpensesDto) {
    return this.financeService.findExpenses(query);
  }

  @Patch("expenses/:id/status")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Update expense status (APPROVED, PAID, REJECTED)" })
  updateExpenseStatus(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body("status") status: ExpenseStatus,
  ) {
    return this.financeService.updateExpenseStatus(id, userId, status);
  }

  // Revenues
  @Post("revenues")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Record a financial revenue or income" })
  createRevenue(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateRevenueDto,
  ) {
    return this.financeService.createRevenue(userId, dto);
  }

  @Get("revenues")
  @ApiOperation({ summary: "List financial revenues with filters" })
  findRevenues(@Query() query: QueryRevenuesDto) {
    return this.financeService.findRevenues(query);
  }

  // Bank Accounts
  @Post("bank-accounts")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Register a bank account" })
  createBankAccount(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateBankAccountDto,
  ) {
    return this.financeService.createBankAccount(userId, dto);
  }

  @Get("bank-accounts")
  @ApiOperation({ summary: "List active bank accounts" })
  findBankAccounts() {
    return this.financeService.findBankAccounts();
  }
}
