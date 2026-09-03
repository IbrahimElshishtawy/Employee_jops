import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { BudgetRepository } from "./budget.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import { CreateBudgetDto, RecordBudgetSpendingDto, QueryBudgetsDto } from "./dto";
import { AuditAction, BudgetStatus, NotificationType } from "@prisma/client";

@Injectable()
export class BudgetService {
  private readonly logger = new Logger(BudgetService.name);

  constructor(
    private readonly repo: BudgetRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async createBudget(userId: string, dto: CreateBudgetDto) {
    const existing = await this.repo.findBudgetByCode(dto.budgetCode);
    if (existing) {
      throw new ConflictException(`Budget with code '${dto.budgetCode}' already exists`);
    }

    if (dto.departmentId) {
      const dept = await this.prisma.department.findUnique({ where: { id: dto.departmentId } });
      if (!dept) throw new NotFoundException(`Department '${dto.departmentId}' not found`);
    }

    if (!dto.lines || dto.lines.length === 0) {
      throw new BadRequestException("Budget must contain at least one budget line");
    }

    const totalAllocated = dto.lines.reduce((sum, line) => sum + line.allocatedAmount, 0);

    const budget = await this.repo.createBudget(dto, totalAllocated);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "Budget",
        entityId: budget.id,
        payload: { budgetCode: budget.budgetCode, totalAllocated, fiscalYear: budget.fiscalYear },
      },
    });

    return budget;
  }

  async findBudgets(query: QueryBudgetsDto) {
    return this.repo.findBudgets(query);
  }

  async findBudgetById(id: string) {
    const budget = await this.repo.findBudgetById(id);
    if (!budget) throw new NotFoundException(`Budget '${id}' not found`);
    return budget;
  }

  async updateBudgetStatus(id: string, userId: string, status: BudgetStatus) {
    await this.findBudgetById(id);
    const updated = await this.repo.updateBudgetStatus(id, status);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "Budget",
        entityId: id,
        payload: { status },
      },
    });

    return updated;
  }

  async recordSpending(userId: string, dto: RecordBudgetSpendingDto) {
    const line = await this.repo.findBudgetLineById(dto.budgetLineId);
    if (!line) throw new NotFoundException(`Budget line '${dto.budgetLineId}' not found`);

    const allocated = Number(line.allocatedAmount);
    const currentSpent = Number(line.spentAmount);
    const newSpent = currentSpent + dto.amount;

    if (newSpent > allocated) {
      this.logger.warn(
        `Budget overrun warning: Line '${line.category}' in budget '${line.budget.budgetCode}' allocated ${allocated}, now spent ${newSpent}`,
      );
    }

    const result = await this.repo.recordSpending(line.budgetId, line.id, dto.amount);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "BudgetLine",
        entityId: line.id,
        payload: {
          budgetId: line.budgetId,
          category: line.category,
          amountSpent: dto.amount,
          newSpentTotal: newSpent,
          isOverrun: newSpent > allocated,
        },
      },
    });

    return result;
  }
}
