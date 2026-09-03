import { Controller, Get, Post, Param, UseGuards } from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from "@nestjs/swagger";
import { SchedulerService } from "./scheduler.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { Role } from "@prisma/client";
import { JobStatusDto } from "./dto/run-job.dto";

@ApiTags("Background Jobs & Scheduler")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("scheduler")
export class SchedulerController {
  constructor(private readonly schedulerService: SchedulerService) {}

  @Get("jobs")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "List all background scheduled jobs and their execution states" })
  @ApiResponse({ status: 200, type: [JobStatusDto] })
  listJobs() {
    return this.schedulerService.listJobs();
  }

  @Post("jobs/:name/run")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Trigger immediate on-demand execution of a background job" })
  runJob(@Param("name") name: string) {
    return this.schedulerService.executeJob(name);
  }
}
