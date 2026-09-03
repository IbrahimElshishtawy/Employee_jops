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
import { BudgetService } from "./budget.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role, BudgetStatus } from "@prisma/client";
import { CreateBudgetDto, RecordBudgetSpendingDto, QueryBudgetsDto } from "./dto";

@ApiTags("Budget Management")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("budget")
export class BudgetController {
  constructor(private readonly budgetService: BudgetService) {}

  @Post()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Create a budget plan with category allocation lines" })
  createBudget(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateBudgetDto,
  ) {
    return this.budgetService.createBudget(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: "List budgets with filters" })
  findBudgets(@Query() query: QueryBudgetsDto) {
    return this.budgetService.findBudgets(query);
  }

  @Get(":id")
  @ApiOperation({ summary: "Get budget details and lines" })
  findBudgetById(@Param("id") id: string) {
    return this.budgetService.findBudgetById(id);
  }

  @Patch(":id/status")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Update budget status (APPROVED, ACTIVE, CLOSED)" })
  updateBudgetStatus(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body("status") status: BudgetStatus,
  ) {
    return this.budgetService.updateBudgetStatus(id, userId, status);
  }

  @Post("spend")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Record spending against a specific budget line" })
  recordSpending(
    @CurrentUser("id") userId: string,
    @Body() dto: RecordBudgetSpendingDto,
  ) {
    return this.budgetService.recordSpending(userId, dto);
  }
}
