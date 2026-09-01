import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from "@nestjs/swagger";
import { OrganizationService } from "./organization.service";
import {
  CreateOrganizationDto,
  UpdateOrganizationDto,
  CreateBranchDto,
  UpdateBranchDto,
  CreateDepartmentDto,
  UpdateDepartmentDto,
  CreateSectionDto,
  UpdateSectionDto,
  CreatePositionDto,
  UpdatePositionDto,
} from "./dto";
import { PaginationQueryDto } from "../../common/dto/pagination.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";

@ApiTags("Organization & Hierarchy")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("organization")
export class OrganizationController {
  constructor(private readonly orgService: OrganizationService) {}

  // ==========================================
  // 1. ORGANIZATIONS
  // ==========================================

  @Post()
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Create organization root (Super Admin only)" })
  @ApiResponse({ status: 201, description: "Organization created" })
  createOrganization(
    @Body() dto: CreateOrganizationDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.createOrganization(dto, userId);
  }

  @Get()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "List all organizations" })
  findAllOrganizations(@Query() query: PaginationQueryDto) {
    return this.orgService.findAllOrganizations(query);
  }

  @Get("tree/hierarchy")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Get complete nested organization structure tree" })
  @ApiQuery({ name: "organizationId", required: false })
  getHierarchy(@Query("organizationId") orgId?: string) {
    return this.orgService.getOrganizationHierarchy(orgId);
  }

  @Get("reporting-tree/:employeeProfileId")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR, Role.EMPLOYEE)
  @ApiOperation({ summary: "Get employee reporting lines (Chain of command & direct reports)" })
  getReportingTree(@Param("employeeProfileId") empId: string) {
    return this.orgService.getEmployeeReportingHierarchy(empId);
  }

  @Get(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Get organization details by ID or code" })
  findOrganizationById(@Param("id") id: string) {
    return this.orgService.findOrganizationById(id);
  }

  @Put(":id")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Update organization details" })
  updateOrganization(
    @Param("id") id: string,
    @Body() dto: UpdateOrganizationDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.updateOrganization(id, dto, userId);
  }

  @Delete(":id")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Delete organization" })
  deleteOrganization(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.deleteOrganization(id, userId);
  }

  // ==========================================
  // 2. BRANCHES / HOTELS
  // ==========================================

  @Post("branches")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Create a branch, hotel, or site location" })
  createBranch(
    @Body() dto: CreateBranchDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.createBranch(dto, userId);
  }

  @Get("branches")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "List branches/hotels" })
  @ApiQuery({ name: "organizationId", required: false })
  findAllBranches(
    @Query() query: PaginationQueryDto,
    @Query("organizationId") orgId?: string,
  ) {
    return this.orgService.findAllBranches(query, orgId);
  }

  @Get("branches/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Get branch details" })
  findBranchById(@Param("id") id: string) {
    return this.orgService.findBranchById(id);
  }

  @Put("branches/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Update branch details" })
  updateBranch(
    @Param("id") id: string,
    @Body() dto: UpdateBranchDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.updateBranch(id, dto, userId);
  }

  @Delete("branches/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Delete branch" })
  deleteBranch(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.deleteBranch(id, userId);
  }

  // ==========================================
  // 3. DEPARTMENTS
  // ==========================================

  @Post("departments")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Create a department or division" })
  createDepartment(
    @Body() dto: CreateDepartmentDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.createDepartment(dto, userId);
  }

  @Get("departments")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "List departments" })
  @ApiQuery({ name: "organizationId", required: false })
  @ApiQuery({ name: "branchId", required: false })
  findAllDepartments(
    @Query() query: PaginationQueryDto,
    @Query("organizationId") orgId?: string,
    @Query("branchId") branchId?: string,
  ) {
    return this.orgService.findAllDepartments(query, orgId, branchId);
  }

  @Get("departments/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Get department details" })
  findDepartmentById(@Param("id") id: string) {
    return this.orgService.findDepartmentById(id);
  }

  @Put("departments/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Update department details" })
  updateDepartment(
    @Param("id") id: string,
    @Body() dto: UpdateDepartmentDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.updateDepartment(id, dto, userId);
  }

  @Delete("departments/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Delete department" })
  deleteDepartment(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.deleteDepartment(id, userId);
  }

  // ==========================================
  // 4. SECTIONS
  // ==========================================

  @Post("sections")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Create a section inside a department" })
  createSection(
    @Body() dto: CreateSectionDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.createSection(dto, userId);
  }

  @Get("sections")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "List sections" })
  @ApiQuery({ name: "departmentId", required: false })
  findAllSections(@Query("departmentId") departmentId?: string) {
    return this.orgService.findAllSections(departmentId);
  }

  @Get("sections/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Get section details" })
  findSectionById(@Param("id") id: string) {
    return this.orgService.findSectionById(id);
  }

  @Put("sections/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Update section" })
  updateSection(
    @Param("id") id: string,
    @Body() dto: UpdateSectionDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.updateSection(id, dto, userId);
  }

  @Delete("sections/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Delete section" })
  deleteSection(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.deleteSection(id, userId);
  }

  // ==========================================
  // 5. POSITIONS
  // ==========================================

  @Post("positions")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Create a job position" })
  createPosition(
    @Body() dto: CreatePositionDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.createPosition(dto, userId);
  }

  @Get("positions")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "List positions" })
  @ApiQuery({ name: "organizationId", required: false })
  @ApiQuery({ name: "departmentId", required: false })
  findAllPositions(
    @Query("organizationId") orgId?: string,
    @Query("departmentId") deptId?: string,
  ) {
    return this.orgService.findAllPositions(orgId, deptId);
  }

  @Get("positions/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER, Role.SUPERVISOR)
  @ApiOperation({ summary: "Get position details" })
  findPositionById(@Param("id") id: string) {
    return this.orgService.findPositionById(id);
  }

  @Put("positions/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Update position" })
  updatePosition(
    @Param("id") id: string,
    @Body() dto: UpdatePositionDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.updatePosition(id, dto, userId);
  }

  @Delete("positions/:id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Delete position" })
  deletePosition(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.orgService.deletePosition(id, userId);
  }
}
