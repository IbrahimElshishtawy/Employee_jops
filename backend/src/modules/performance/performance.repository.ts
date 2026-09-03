import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import {
  CreateKPIDto,
  CreateGoalDto,
  UpdateGoalProgressDto,
  CreatePerformanceReviewDto,
  QueryGoalsDto,
  QueryReviewsDto,
} from "./dto";
import { Prisma, GoalStatus, ReviewStatus } from "@prisma/client";

@Injectable()
export class PerformanceRepository {
  constructor(private readonly prisma: PrismaService) {}

  async generateReviewNumber(): Promise<string> {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, "");
    const count = await this.prisma.performanceReview.count();
    const seq = (count + 1).toString().padStart(4, "0");
    return `PRV-${today}-${seq}`;
  }

  // ============================================================
  // KPIs
  // ============================================================

  async createKPI(dto: CreateKPIDto) {
    return this.prisma.employeeKPI.create({
      data: {
        code: dto.code,
        title: dto.title,
        description: dto.description,
        targetValue: new Prisma.Decimal(dto.targetValue),
        unit: dto.unit || "PERCENT",
        category: dto.category || "OPERATIONAL",
        departmentId: dto.departmentId,
      },
    });
  }

  async findKPIs(departmentId?: string) {
    return this.prisma.employeeKPI.findMany({
      where: departmentId ? { departmentId } : undefined,
      orderBy: { code: "asc" },
    });
  }

  async findKPIById(id: string) {
    return this.prisma.employeeKPI.findUnique({
      where: { id },
    });
  }

  async findKPIByCode(code: string) {
    return this.prisma.employeeKPI.findUnique({
      where: { code },
    });
  }

  // ============================================================
  // GOALS
  // ============================================================

  async createGoal(dto: CreateGoalDto) {
    return this.prisma.performanceGoal.create({
      data: {
        employeeId: dto.employeeId,
        kpiId: dto.kpiId,
        title: dto.title,
        description: dto.description,
        targetValue: new Prisma.Decimal(dto.targetValue),
        currentValue: new Prisma.Decimal(0),
        deadline: dto.deadline ? new Date(dto.deadline) : null,
        weight: dto.weight || 100,
        status: GoalStatus.NOT_STARTED,
      },
      include: {
        kpi: true,
        employee: { select: { id: true, firstName: true, lastName: true } },
      },
    });
  }

  async findGoals(query: QueryGoalsDto) {
    const { page = 1, limit = 20, employeeId, status } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.PerformanceGoalWhereInput = {};
    if (employeeId) where.employeeId = employeeId;
    if (status) where.status = status;

    const [total, items] = await Promise.all([
      this.prisma.performanceGoal.count({ where }),
      this.prisma.performanceGoal.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          kpi: true,
          employee: { select: { id: true, firstName: true, lastName: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findGoalById(id: string) {
    return this.prisma.performanceGoal.findUnique({
      where: { id },
      include: {
        kpi: true,
        employee: true,
      },
    });
  }

  async updateGoalProgress(id: string, dto: UpdateGoalProgressDto) {
    const data: Prisma.PerformanceGoalUpdateInput = {
      currentValue: new Prisma.Decimal(dto.currentValue),
    };
    if (dto.status) data.status = dto.status;

    return this.prisma.performanceGoal.update({
      where: { id },
      data,
      include: { kpi: true, employee: true },
    });
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  async createReview(
    reviewerProfileId: string,
    dto: CreatePerformanceReviewDto,
    reviewNumber: string,
  ) {
    return this.prisma.performanceReview.create({
      data: {
        reviewNumber,
        employeeId: dto.employeeId,
        reviewerId: reviewerProfileId,
        cycleName: dto.cycleName,
        periodStart: new Date(dto.periodStart),
        periodEnd: new Date(dto.periodEnd),
        overallRating: new Prisma.Decimal(dto.overallRating),
        strengths: dto.strengths,
        improvements: dto.improvements,
        comments: dto.comments,
        status: ReviewStatus.SUBMITTED,
      },
      include: {
        employee: {
          include: { user: { select: { email: true } } },
        },
        reviewer: {
          include: { user: { select: { email: true } } },
        },
      },
    });
  }

  async findReviews(query: QueryReviewsDto) {
    const { page = 1, limit = 20, employeeId, status } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.PerformanceReviewWhereInput = {};
    if (employeeId) where.employeeId = employeeId;
    if (status) where.status = status;

    const [total, items] = await Promise.all([
      this.prisma.performanceReview.count({ where }),
      this.prisma.performanceReview.findMany({
        where,
        skip,
        take: limit,
        orderBy: { periodEnd: "desc" },
        include: {
          employee: { select: { id: true, firstName: true, lastName: true } },
          reviewer: { select: { id: true, firstName: true, lastName: true } },
        },
      }),
    ]);

    return {
      items,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async findReviewById(id: string) {
    return this.prisma.performanceReview.findUnique({
      where: { id },
      include: {
        employee: {
          include: { user: { select: { email: true } } },
        },
        reviewer: {
          include: { user: { select: { email: true } } },
        },
      },
    });
  }

  async acknowledgeReview(id: string) {
    return this.prisma.performanceReview.update({
      where: { id },
      data: { status: ReviewStatus.ACKNOWLEDGED },
    });
  }
}
