import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { OnboardingService } from "./onboarding.service";
import { CreateOnboardingWorkflowDto } from "./dto/create-onboarding-workflow.dto";
import { UpdateOnboardingWorkflowDto } from "./dto/update-onboarding-workflow.dto";
import { CreateOnboardingTaskDto } from "./dto/create-onboarding-task.dto";
import { UpdateOnboardingTaskDto } from "./dto/update-onboarding-task.dto";
import { CompleteOnboardingTaskDto } from "./dto/complete-onboarding-task.dto";
import { QueryOnboardingWorkflowsDto } from "./dto/query-onboarding.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { PermissionsGuard } from "../../common/guards/permissions.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RequirePermissions } from "../../common/decorators/permissions.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";

@ApiTags("Employee Onboarding")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Controller("onboarding")
export class OnboardingController {
  constructor(private readonly onboardingService: OnboardingService) {}

  @Post("workflows")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("onboarding:create")
  @ApiOperation({ summary: "Initialize an onboarding workflow and standard checklist" })
  createWorkflow(
    @Body() dto: CreateOnboardingWorkflowDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.onboardingService.createWorkflow(dto, userId);
  }

  @Get("workflows")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("onboarding:read")
  @ApiOperation({ summary: "List and track all employee onboarding workflows" })
  getWorkflows(@Query() query: QueryOnboardingWorkflowsDto) {
    return this.onboardingService.getWorkflows(query);
  }

  @Get("workflows/my")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE)
  @ApiOperation({ summary: "Get current employee onboarding checklist and roadmap (Self-Service)" })
  getMyWorkflow(@CurrentUser("id") userId: string) {
    return this.onboardingService.getMyWorkflow(userId);
  }

  @Get("workflows/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("onboarding:read")
  @ApiOperation({ summary: "Get onboarding workflow details with complete task list" })
  getWorkflowById(@Param("id") id: string) {
    return this.onboardingService.getWorkflowById(id);
  }

  @Patch("workflows/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("onboarding:update")
  @ApiOperation({ summary: "Update onboarding workflow dates or status" })
  updateWorkflow(
    @Param("id") id: string,
    @Body() dto: UpdateOnboardingWorkflowDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.onboardingService.updateWorkflow(id, dto, userId);
  }

  @Patch("workflows/:id/finalize")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("onboarding:manage")
  @ApiOperation({ summary: "Finalize employee onboarding and unlock full profile" })
  finalizeWorkflow(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.onboardingService.finalizeWorkflow(id, userId);
  }

  @Post("tasks")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("onboarding:update")
  @ApiOperation({ summary: "Add a custom checklist task to an onboarding workflow" })
  createTask(
    @Body() dto: CreateOnboardingTaskDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.onboardingService.createTask(dto, userId);
  }

  @Patch("tasks/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("onboarding:update")
  @ApiOperation({ summary: "Update task metadata, category, or assignment" })
  updateTask(
    @Param("id") id: string,
    @Body() dto: UpdateOnboardingTaskDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.onboardingService.updateTask(id, dto, userId);
  }

  @Patch("tasks/:id/complete")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE)
  @ApiOperation({ summary: "Complete or toggle onboarding task status" })
  completeTask(
    @Param("id") id: string,
    @Body() dto: CompleteOnboardingTaskDto,
    @CurrentUser("id") currentUserId: string,
  ) {
    return this.onboardingService.completeTask(id, dto, currentUserId);
  }

  @Delete("tasks/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @RequirePermissions("onboarding:delete")
  @ApiOperation({ summary: "Delete an onboarding checklist task" })
  deleteTask(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.onboardingService.deleteTask(id, userId);
  }
}
