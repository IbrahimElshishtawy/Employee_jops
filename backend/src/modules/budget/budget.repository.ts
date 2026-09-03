import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { CreateBudgetDto, QueryBudgetsDto } from "./dto";
import { Prisma, BudgetStatus } from "@prisma/client";

@Injectable()
export class BudgetRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createBudget(dto: CreateBudgetDto, totalAllocated: number) {
    return this.prisma.budget.create({
      data: {
        budgetCode: dto.budgetCode,
        title: dto.title,
        fiscalYear: dto.fiscalYear,
        periodType: dto.periodType,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        departmentId: dto.departmentId,
        status: dto.status || BudgetStatus.DRAFT,
        notes: dto.notes,
        totalAllocated: new Prisma.Decimal(totalAllocated),
        totalSpent: new Prisma.Decimal(0),
        lines: {
          create: dto.lines.map((line) => ({
            category: line.category,
            allocatedAmount: new Prisma.Decimal(line.allocatedAmount),
            spentAmount: new Prisma.Decimal(0),
            notes: line.notes,
          })),
        },
      },
      include: {
        department: true,
        lines: true,
      },
    });
  }

  async findBudgets(query: QueryBudgetsDto) {
    const { page = 1, limit = 20, fiscalYear, status, departmentId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.BudgetWhereInput = {};
    if (fiscalYear) where.fiscalYear = fiscalYear;
    if (status) where.status = status;
    if (departmentId) where.departmentId = departmentId;

    const [total, items] = await Promise.all([
      this.prisma.budget.count({ where }),
      this.prisma.budget.findMany({
        where,
        skip,
        take: limit,
        orderBy: { fiscalYear: "desc" },
        include: {
          department: true,
          lines: true,
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findBudgetById(id: string) {
    return this.prisma.budget.findUnique({
      where: { id },
      include: {
        department: true,
        lines: true,
      },
    });
  }

  async findBudgetByCode(budgetCode: string) {
    return this.prisma.budget.findUnique({
      where: { budgetCode },
    });
  }

  async updateBudgetStatus(id: string, status: BudgetStatus) {
    return this.prisma.budget.update({
      where: { id },
      data: { status },
      include: { lines: true },
    });
  }

  async findBudgetLineById(id: string) {
    return this.prisma.budgetLine.findUnique({
      where: { id },
      include: { budget: true },
    });
  }

  async recordSpending(budgetId: string, budgetLineId: string, amount: number) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Increment budget line spent
      const updatedLine = await tx.budgetLine.update({
        where: { id: budgetLineId },
        data: {
          spentAmount: { increment: amount },
        },
      });

      // 2. Increment budget total spent
      const updatedBudget = await tx.budget.update({
        where: { id: budgetId },
        data: {
          totalSpent: { increment: amount },
        },
        include: { lines: true },
      });

      return { updatedBudget, updatedLine };
    });
  }
}
