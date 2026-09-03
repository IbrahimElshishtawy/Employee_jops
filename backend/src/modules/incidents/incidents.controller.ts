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
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from "@nestjs/swagger";
import { IncidentsService } from "./incidents.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";
import {
  CreateIncidentDto,
  UpdateIncidentDto,
  AddInvestigationDto,
  AddCorrectiveActionDto,
  QueryIncidentsDto,
} from "./dto";

@ApiTags("Incident & Safety Management")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("incidents")
export class IncidentsController {
  constructor(private readonly incidentsService: IncidentsService) {}

  @Post()
  @ApiOperation({ summary: "Report an incident (safety, security, guest, employee)" })
  @ApiResponse({ status: 201, description: "Incident reported" })
  createIncident(
    @CurrentUser("id") userId: string,
    @Body() dto: CreateIncidentDto,
  ) {
    return this.incidentsService.createIncident(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: "List incidents with filters and search" })
  findIncidents(@Query() query: QueryIncidentsDto) {
    return this.incidentsService.findIncidents(query);
  }

  @Get(":id")
  @ApiOperation({ summary: "Get incident details, investigations, and corrective actions" })
  findIncidentById(@Param("id") id: string) {
    return this.incidentsService.findIncidentById(id);
  }

  @Patch(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Update incident status or severity" })
  updateIncident(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
    @Body() dto: UpdateIncidentDto,
  ) {
    return this.incidentsService.updateIncident(id, userId, dto);
  }

  @Post(":id/investigation")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Add an investigation finding and root cause analysis" })
  addInvestigation(
    @Param("id") incidentId: string,
    @CurrentUser("id") userId: string,
    @Body() dto: AddInvestigationDto,
  ) {
    return this.incidentsService.addInvestigation(incidentId, userId, dto);
  }

  @Post(":id/corrective-actions")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Assign a corrective action for an incident" })
  addCorrectiveAction(
    @Param("id") incidentId: string,
    @CurrentUser("id") userId: string,
    @Body() dto: AddCorrectiveActionDto,
  ) {
    return this.incidentsService.addCorrectiveAction(incidentId, userId, dto);
  }

  @Patch("corrective-actions/:actionId/resolve")
  @ApiOperation({ summary: "Resolve and close a corrective action" })
  resolveCorrectiveAction(
    @Param("actionId") actionId: string,
    @CurrentUser("id") userId: string,
    @Body("resolutionNotes") resolutionNotes?: string,
  ) {
    return this.incidentsService.resolveCorrectiveAction(actionId, userId, resolutionNotes);
  }
}
