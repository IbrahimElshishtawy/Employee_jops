import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { PerformanceRepository } from "./performance.repository";
import { PrismaService } from "../../prisma/prisma.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  CreateKPIDto,
  CreateGoalDto,
  UpdateGoalProgressDto,
  CreatePerformanceReviewDto,
  QueryGoalsDto,
  QueryReviewsDto,
} from "./dto";
import {
  AuditAction,
  GoalStatus,
  ReviewStatus,
  UserStatus,
  NotificationType,
} from "@prisma/client";

@Injectable()
export class PerformanceService {
  private readonly logger = new Logger(PerformanceService.name);

  constructor(
    private readonly repo: PerformanceRepository,
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ============================================================
  // KPIs
  // ============================================================

  async createKPI(userId: string, dto: CreateKPIDto) {
    const existing = await this.repo.findKPIByCode(dto.code);
    if (existing) {
      throw new ConflictException(`KPI with code '${dto.code}' already exists`);
    }

    const kpi = await this.repo.createKPI(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "EmployeeKPI",
        entityId: kpi.id,
        payload: { code: kpi.code, title: kpi.title },
      },
    });

    return kpi;
  }

  async findKPIs(departmentId?: string) {
    return this.repo.findKPIs(departmentId);
  }

  // ============================================================
  // GOALS
  // ============================================================

  async createGoal(userId: string, dto: CreateGoalDto) {
    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.employeeId },
      include: { user: true },
    });
    if (!employee)
      throw new NotFoundException(`Employee '${dto.employeeId}' not found`);

    if (dto.kpiId) {
      const kpi = await this.repo.findKPIById(dto.kpiId);
      if (!kpi) throw new NotFoundException(`KPI '${dto.kpiId}' not found`);
    }

    const goal = await this.repo.createGoal(dto);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "PerformanceGoal",
        entityId: goal.id,
        payload: {
          employeeId: dto.employeeId,
          title: goal.title,
          targetValue: dto.targetValue,
        },
      },
    });

    return goal;
  }

  async findGoals(query: QueryGoalsDto) {
    return this.repo.findGoals(query);
  }

  async updateGoalProgress(
    id: string,
    userId: string,
    dto: UpdateGoalProgressDto,
  ) {
    const goal = await this.repo.findGoalById(id);
    if (!goal) throw new NotFoundException(`Goal '${id}' not found`);

    let status = dto.status || goal.status;
    if (
      dto.currentValue >= Number(goal.targetValue) &&
      status !== GoalStatus.ACHIEVED
    ) {
      status = GoalStatus.ACHIEVED;
    } else if (dto.currentValue > 0 && status === GoalStatus.NOT_STARTED) {
      status = GoalStatus.IN_PROGRESS;
    }

    const updated = await this.repo.updateGoalProgress(id, {
      ...dto,
      status,
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "PerformanceGoal",
        entityId: id,
        payload: { currentValue: dto.currentValue, status },
      },
    });

    return updated;
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  async createReview(userId: string, dto: CreatePerformanceReviewDto) {
    const reviewer = await this.prisma.employeeProfile.findUnique({
      where: { userId },
      include: { user: true },
    });
    if (!reviewer || reviewer.user?.status !== UserStatus.ACTIVE) {
      throw new BadRequestException(
        "Active employee profile required for reviewer",
      );
    }

    const employee = await this.prisma.employeeProfile.findUnique({
      where: { id: dto.employeeId },
      include: { user: true },
    });
    if (!employee)
      throw new NotFoundException(`Employee '${dto.employeeId}' not found`);

    const reviewNumber = await this.repo.generateReviewNumber();
    const review = await this.repo.createReview(reviewer.id, dto, reviewNumber);

    // Notify employee of performance review
    if (employee.user?.id) {
      await this.notificationsService
        .sendNotification(
          employee.user.id,
          "Performance Review Completed",
          `Your performance review for cycle '${dto.cycleName}' has been submitted. Rating: ${dto.overallRating}/5.0`,
          NotificationType.GENERAL_ANNOUNCEMENT,
          { reviewId: review.id, reviewNumber },
        )
        .catch(() => {});
    }

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.CREATE,
        entity: "PerformanceReview",
        entityId: review.id,
        payload: {
          reviewNumber,
          employeeId: dto.employeeId,
          overallRating: dto.overallRating,
        },
      },
    });

    return review;
  }

  async findReviews(query: QueryReviewsDto) {
    return this.repo.findReviews(query);
  }

  async findReviewById(id: string) {
    const review = await this.repo.findReviewById(id);
    if (!review) throw new NotFoundException(`Review '${id}' not found`);
    return review;
  }

  async acknowledgeReview(id: string, userId: string) {
    await this.findReviewById(id);
    const updated = await this.repo.acknowledgeReview(id);

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: AuditAction.UPDATE,
        entity: "PerformanceReview",
        entityId: id,
        payload: { status: ReviewStatus.ACKNOWLEDGED },
      },
    });

    return updated;
  }
}
