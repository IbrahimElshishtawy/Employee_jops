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
import { HrService } from "./hr.service";
import { HrEmployeeQueryDto } from "./dto/hr-query.dto";
import { UpdateEmployeeAssignmentDto } from "./dto/update-employee-assignment.dto";
import { CreateEmployeeDocumentDto } from "./dto/create-employee-document.dto";
import { UpdateEmployeeDocumentDto } from "./dto/update-employee-document.dto";
import { VerifyEmployeeDocumentDto } from "./dto/verify-employee-document.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { PermissionsGuard } from "../../common/guards/permissions.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RequirePermissions } from "../../common/decorators/permissions.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";

@ApiTags("HR Management")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Controller("hr")
export class HrController {
  constructor(private readonly hrService: HrService) {}

  @Get("employees")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("employees:read")
  @ApiOperation({
    summary:
      "Get enriched paginated employee list with organizational & hierarchy filters",
  })
  getEmployees(@Query() query: HrEmployeeQueryDto) {
    return this.hrService.getEmployees(query);
  }

  @Get("employees/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("employees:read")
  @ApiOperation({
    summary:
      "Get detailed HR employee profile with full hierarchy, documents, and onboarding status",
  })
  getEmployeeById(@Param("id") id: string) {
    return this.hrService.getEmployeeById(id);
  }

  @Patch("employees/:id/assignment")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("employees:update")
  @ApiOperation({
    summary:
      "Reassign employee department, position, section, manager, workplace, or schedule",
  })
  updateEmployeeAssignment(
    @Param("id") id: string,
    @Body() dto: UpdateEmployeeAssignmentDto,
    @CurrentUser("id") updaterId: string,
  ) {
    return this.hrService.updateEmployeeAssignment(id, dto, updaterId);
  }

  @Post("employees/:id/documents")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("employees:manage")
  @ApiOperation({
    summary: "Add document metadata for employee",
  })
  addEmployeeDocument(
    @Param("id") employeeId: string,
    @Body() dto: CreateEmployeeDocumentDto,
    @CurrentUser("id") creatorId: string,
  ) {
    return this.hrService.addEmployeeDocument(employeeId, dto, creatorId);
  }

  @Get("employees/:id/documents")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @RequirePermissions("employees:read")
  @ApiOperation({
    summary: "List all document records and verification statuses for employee",
  })
  getEmployeeDocuments(@Param("id") employeeId: string) {
    return this.hrService.getEmployeeDocuments(employeeId);
  }

  @Patch("documents/:docId/verify")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("employees:manage")
  @ApiOperation({
    summary: "Verify or revoke verification of employee document metadata",
  })
  verifyEmployeeDocument(
    @Param("docId") docId: string,
    @Body() dto: VerifyEmployeeDocumentDto,
    @CurrentUser("id") verifierId: string,
  ) {
    return this.hrService.verifyEmployeeDocument(docId, dto, verifierId);
  }

  @Patch("documents/:docId")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @RequirePermissions("employees:update")
  @ApiOperation({
    summary: "Update document metadata",
  })
  updateEmployeeDocument(
    @Param("docId") docId: string,
    @Body() dto: UpdateEmployeeDocumentDto,
    @CurrentUser("id") updaterId: string,
  ) {
    return this.hrService.updateEmployeeDocument(docId, dto, updaterId);
  }

  @Delete("documents/:docId")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @RequirePermissions("employees:delete")
  @ApiOperation({
    summary: "Delete employee document metadata",
  })
  deleteEmployeeDocument(
    @Param("docId") docId: string,
    @CurrentUser("id") deleterId: string,
  ) {
    return this.hrService.deleteEmployeeDocument(docId, deleterId);
  }
}
