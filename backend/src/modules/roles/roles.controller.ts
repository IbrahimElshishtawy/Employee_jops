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
} from "@nestjs/swagger";
import { RolesService } from "./roles.service";
import {
  CreateRoleDto,
  UpdateRoleDto,
  SyncRolePermissionsDto,
  AssignUserRolesDto,
} from "./dto";
import { PaginationQueryDto } from "../../common/dto/pagination.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";

@ApiTags("Roles")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("roles")
export class RolesController {
  constructor(private readonly rolesService: RolesService) {}

  @Post()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({
    summary: "Create a custom role with optional initial permissions",
  })
  @ApiResponse({ status: 201, description: "Role created successfully" })
  create(@Body() dto: CreateRoleDto, @CurrentUser("id") userId: string) {
    return this.rolesService.create(dto, userId);
  }

  @Get()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "List all roles with pagination and search" })
  findAll(@Query() query: PaginationQueryDto) {
    return this.rolesService.findAll(query);
  }

  @Get("users/:userId")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Get effective roles and permissions of a user" })
  getUserRolesAndPermissions(@Param("userId") userId: string) {
    return this.rolesService.getUserRolesAndPermissions(userId);
  }

  @Post("users/assign")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Assign database roles to a specific user" })
  assignRolesToUser(
    @Body() dto: AssignUserRolesDto,
    @CurrentUser("id") assignerUserId: string,
  ) {
    return this.rolesService.assignRolesToUser(dto, assignerUserId);
  }

  @Get(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Get role details by ID or slug" })
  findOne(@Param("id") id: string) {
    return this.rolesService.findOne(id);
  }

  @Put(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Update role details" })
  update(
    @Param("id") id: string,
    @Body() dto: UpdateRoleDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.rolesService.update(id, dto, userId);
  }

  @Delete(":id")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({
    summary: "Delete a custom role (System roles cannot be deleted)",
  })
  remove(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.rolesService.remove(id, userId);
  }

  @Put(":id/permissions")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Synchronize permission matrix for a role" })
  syncRolePermissions(
    @Param("id") id: string,
    @Body() dto: SyncRolePermissionsDto,
    @CurrentUser("id") userId: string,
  ) {
    return this.rolesService.syncRolePermissions(id, dto, userId);
  }
}
