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
  ApiResponse,
  ApiBearerAuth,
} from "@nestjs/swagger";
import { PermissionsService } from "./permissions.service";
import { CreatePermissionDto, QueryPermissionsDto } from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Role } from "@prisma/client";

@ApiTags("Permissions")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("permissions")
export class PermissionsController {
  constructor(private readonly permissionsService: PermissionsService) {}

  @Post()
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({
    summary: "Create a new granular permission (Super Admin only)",
  })
  @ApiResponse({ status: 201, description: "Permission created successfully" })
  create(@Body() dto: CreatePermissionDto, @CurrentUser("id") userId: string) {
    return this.permissionsService.create(dto, userId);
  }

  @Get()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({
    summary: "List all permissions with filtering and pagination",
  })
  findAll(@Query() query: QueryPermissionsDto) {
    return this.permissionsService.findAll(query);
  }

  @Get("catalog/grouped")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Get all permissions grouped by domain module" })
  getGroupedByModule() {
    return this.permissionsService.getGroupedByModule();
  }

  @Get(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN, Role.HR_MANAGER)
  @ApiOperation({ summary: "Get permission by ID or slug" })
  findOne(@Param("id") id: string) {
    return this.permissionsService.findOne(id);
  }
}
