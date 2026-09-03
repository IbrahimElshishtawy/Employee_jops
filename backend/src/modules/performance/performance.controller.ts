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
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { PerformanceService } from "./performance.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
import {
  CreateKPIDto,
  CreateGoalDto,
  UpdateGoalProgressDto,
  CreatePerformanceReviewDto,
  QueryGoalsDto,
  QueryReviewsDto,
} from "./dto";

@ApiTags("Performance Management")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("performance")
export class PerformanceController {
  constructor(private readonly performanceService: PerformanceService) {}

  // KPIs
  @Post("kpis")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Define an employee KPI" })
  createKPI(@CurrentUser("id") userId: string, @Body() dto: CreateKPIDto) {
    return this.performanceService.createKPI(userId, dto);
  }

  @Get("kpis")
  @ApiOperation({ summary: "List employee KPIs" })
  findKPIs(@Query("departmentId") departmentId?: string) {
    return this.performanceService.findKPIs(departmentId);
  }

  // Goals
  @Post("goals")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Assign a performance goal to an employee" })
  createGoal(@CurrentUser("id") userId: string, @Body() dto: CreateGoalDto) {
    return this.performanceService.createGoal(userId, dto);
  }

  @Get("goals")
  @ApiOperation({ summary: "List performance goals with filters" })
  findGoals(@Query() query: QueryGoalsDto) {
    return this.performanceService.findGoals(query);
  }

  @Patch("goals/:id/progress")
  @ApiOperation({
    summary: "Update goal progress value and trigger auto-achievement",
  })
  updateGoalProgress(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateGoalProgressDto,
  ) {
    return this.performanceService.updateGoalProgress(id, userId, dto);
  }

  // Reviews
  @Post("reviews")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Submit a performance review for an employee" })
  createReview(
    @CurrentUser("id") userId: string,
    @Body() dto: CreatePerformanceReviewDto,
  ) {
    return this.performanceService.createReview(userId, dto);
  }

  @Get("reviews")
  @ApiOperation({ summary: "List performance reviews with filters" })
  findReviews(@Query() query: QueryReviewsDto) {
    return this.performanceService.findReviews(query);
  }

  @Get("reviews/:id")
  @ApiOperation({
    summary: "Get review details including strengths and improvement areas",
  })
  findReviewById(@Param("id") id: string) {
    return this.performanceService.findReviewById(id);
  }

  @Post("reviews/:id/acknowledge")
  @ApiOperation({
    summary:
      "Employee acknowledges receipt and discussion of performance review",
  })
  acknowledgeReview(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.performanceService.acknowledgeReview(id, userId);
  }
}
