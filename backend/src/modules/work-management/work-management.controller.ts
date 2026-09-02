import {
  Controller,
  Get,
  Post,
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
import { WorkManagementService } from "./work-management.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
import {
  SubmitTaskReportDto,
  ReviewTaskReportDto,
  QueryWorkloadDto,
} from "./dto";

@ApiTags("Work Management & Approvals")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("work-management")
export class WorkManagementController {
  constructor(private readonly workService: WorkManagementService) {}

  @Post("tasks/:id/report")
  @ApiOperation({
    summary:
      "Employee submits task execution report upon finishing work (Transitions task to PENDING_REVIEW)",
  })
  @ApiResponse({ status: 201, description: "Report submitted and sent for manager review" })
  submitTaskReport(
    @Param("id") taskId: string,
    @CurrentUser("id") userId: string,
    @Body() dto: SubmitTaskReportDto,
  ) {
    return this.workService.submitTaskReport(taskId, userId, dto);
  }

  @Post("tasks/:id/review")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({
    summary:
      "Manager reviews task report: APPROVE (completes task) or REJECT (returns to IN_PROGRESS)",
  })
  @ApiResponse({ status: 200, description: "Review decision processed successfully" })
  reviewTaskReport(
    @Param("id") taskId: string,
    @CurrentUser("id") reviewerUserId: string,
    @Body() dto: ReviewTaskReportDto,
  ) {
    return this.workService.reviewTaskReport(taskId, reviewerUserId, dto);
  }

  @Get("pending-reviews")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Get queue of pending task reviews for manager" })
  getPendingReviews(
    @CurrentUser("id") userId: string,
    @Query("page") page?: number,
    @Query("limit") limit?: number,
  ) {
    return this.workService.getPendingReviews(userId, page, limit);
  }

  @Get("department-workload")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Get team/department workload breakdown, task distribution & capacity" })
  getDepartmentWorkload(
    @Query() query: QueryWorkloadDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.workService.getDepartmentWorkload(query, userId);
  }

  @Post("check-overdue")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Trigger low-resource scan to flag overdue tasks" })
  checkOverdueTasks() {
    return this.workService.checkOverdueTasks();
  }
}
