import { Body, Controller, Get, Post, Query, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import { Role } from "@prisma/client";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Roles } from "../../common/decorators/roles.decorator";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { MarkAbsenceDto } from "./dto/mark-absence.dto";
import { WorkforceQueryDto } from "./dto/workforce-query.dto";
import { WorkforceService } from "./workforce.service";

@ApiTags("Workforce Operations & Analytics")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
@Controller("workforce")
export class WorkforceController {
  constructor(private readonly workforceService: WorkforceService) {}

  @Get("live-status")
  @ApiOperation({
    summary:
      "Get real-time live presence dashboard for today (checked in, not checked in, late, on leave)",
  })
  getLiveStatus(@Query() query: WorkforceQueryDto) {
    return this.workforceService.getLiveStatus(query);
  }

  @Get("statistics")
  @ApiOperation({
    summary:
      "Get consolidated attendance & workforce statistics (attendance rate, total work hours, overtime, late)",
  })
  getStatistics(@Query() query: WorkforceQueryDto) {
    return this.workforceService.getStatistics(query);
  }

  @Get("summary")
  @ApiOperation({
    summary:
      "Get daily / periodic aggregated attendance trends with pagination",
  })
  getSummary(@Query() query: WorkforceQueryDto) {
    return this.workforceService.getSummary(query);
  }

  @Get("departments")
  @ApiOperation({
    summary:
      "Get department-level workforce distribution, attendance rates, and hours",
  })
  getDepartmentWorkforce(@Query() query: WorkforceQueryDto) {
    return this.workforceService.getDepartmentWorkforce(query);
  }

  @Get("workplaces")
  @ApiOperation({
    summary:
      "Get workplace/branch-level workforce distribution and performance metrics",
  })
  getWorkplaceWorkforce(@Query() query: WorkforceQueryDto) {
    return this.workforceService.getWorkplaceWorkforce(query);
  }

  @Get("absent-employees")
  @ApiOperation({
    summary:
      "Identify employees scheduled to work on a date who have no check-in and no approved leave",
  })
  getAbsentEmployees(
    @Query("date") date?: string,
    @Query("workplaceId") workplaceId?: string,
    @Query("department") department?: string,
  ) {
    return this.workforceService.getAbsentEmployees(
      date,
      workplaceId,
      department,
    );
  }

  @Post("mark-absent")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary:
      "Batch/auto mark identified absent employees with audit trail recording",
  })
  markAbsences(
    @CurrentUser("id") actorUserId: string,
    @Body() dto: MarkAbsenceDto,
  ) {
    return this.workforceService.markAbsences(actorUserId, dto);
  }

  @Get("overtime-summary")
  @ApiOperation({
    summary: "Get top overtime workers and total overtime hours within period",
  })
  getOvertimeSummary(@Query() query: WorkforceQueryDto) {
    return this.workforceService.getOvertimeSummary(query);
  }
}
