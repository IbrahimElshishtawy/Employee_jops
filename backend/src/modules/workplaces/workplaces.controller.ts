import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { WorkplacesService } from "./workplaces.service";
import { CreateWorkplaceDto } from "./dto/create-workplace.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { Role } from "@prisma/client";

@ApiTags("Workplaces")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("workplaces")
export class WorkplacesController {
  constructor(private readonly workplacesService: WorkplacesService) {}

  @Post()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Create a new workplace / branch" })
  create(@Body() dto: CreateWorkplaceDto) {
    return this.workplacesService.create(dto);
  }

  @Get()
  @Roles(
    Role.SUPER_ADMIN,
    Role.HR_ADMIN,
    Role.HR_MANAGER,
    Role.SUPERVISOR,
    Role.EMPLOYEE,
  )
  @ApiOperation({ summary: "List all active workplaces" })
  findAll() {
    return this.workplacesService.findAll();
  }

  @Get(":id")
  @Roles(
    Role.SUPER_ADMIN,
    Role.HR_ADMIN,
    Role.HR_MANAGER,
    Role.SUPERVISOR,
    Role.EMPLOYEE,
  )
  @ApiOperation({ summary: "Get workplace details including geofence" })
  findOne(@Param("id") id: string) {
    return this.workplacesService.findOne(id);
  }

  @Patch(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Update workplace settings & geofence" })
  update(@Param("id") id: string, @Body() dto: Partial<CreateWorkplaceDto>) {
    return this.workplacesService.update(id, dto);
  }

  @Delete(":id")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Delete workplace" })
  remove(@Param("id") id: string) {
    return this.workplacesService.remove(id);
  }
}
