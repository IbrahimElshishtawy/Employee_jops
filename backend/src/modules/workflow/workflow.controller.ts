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
  HttpStatus,
  HttpCode,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
  ApiResponse,
} from "@nestjs/swagger";
import { WorkflowService } from "./workflow.service";
import { CreateWorkflowDto, QueryWorkflowDto, UpdateWorkflowDto } from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role, RequestType } from "@prisma/client";

@ApiTags("Workflows")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("workflows")
export class WorkflowController {
  constructor(private readonly workflowService: WorkflowService) {}

  @Post()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Create a new approval workflow definition" })
  @ApiResponse({ status: 201, description: "Workflow created successfully" })
  create(
    @CurrentUser("id") currentUserId: string,
    @Body() dto: CreateWorkflowDto,
  ) {
    return this.workflowService.create(dto, currentUserId);
  }

  @Get()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "List workflows with filtering and pagination" })
  findAll(@Query() query: QueryWorkflowDto) {
    return this.workflowService.findAll(query);
  }

  @Post("match-preview")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Preview/Simulate workflow matching for a given request criteria" })
  matchPreview(
    @Body()
    body: {
      requestType: RequestType;
      departmentId?: string;
      role?: Role;
      days?: number;
      amount?: number;
    },
  ) {
    return this.workflowService.matchWorkflow(body);
  }

  @Get(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Get workflow definition by ID" })
  @ApiParam({ name: "id", description: "Workflow UUID" })
  findOne(@Param("id") id: string) {
    return this.workflowService.findOne(id);
  }

  @Patch(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Update workflow definition" })
  @ApiParam({ name: "id", description: "Workflow UUID" })
  update(
    @Param("id") id: string,
    @CurrentUser("id") currentUserId: string,
    @Body() dto: UpdateWorkflowDto,
  ) {
    return this.workflowService.update(id, dto, currentUserId);
  }

  @Delete(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Delete workflow definition" })
  @ApiParam({ name: "id", description: "Workflow UUID" })
  remove(
    @Param("id") id: string,
    @CurrentUser("id") currentUserId: string,
  ) {
    return this.workflowService.remove(id, currentUserId);
  }
}
