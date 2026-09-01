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
import { SchedulesService } from "./schedules.service";
import { CreateScheduleDto, UpdateScheduleDto } from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { Role } from "@prisma/client";

@ApiTags("Schedules")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("schedules")
export class SchedulesController {
  constructor(private readonly schedulesService: SchedulesService) {}

  @Post()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Create a new shift schedule" })
  create(@Body() dto: CreateScheduleDto) {
    return this.schedulesService.create(dto);
  }

  @Get()
  @Roles(
    Role.SUPER_ADMIN,
    Role.HR_ADMIN,
    Role.HR_MANAGER,
    Role.SUPERVISOR,
    Role.EMPLOYEE,
  )
  @ApiOperation({ summary: "List all active shift schedules" })
  findAll() {
    return this.schedulesService.findAll();
  }

  @Get(":id")
  @Roles(
    Role.SUPER_ADMIN,
    Role.HR_ADMIN,
    Role.HR_MANAGER,
    Role.SUPERVISOR,
    Role.EMPLOYEE,
  )
  @ApiOperation({ summary: "Get schedule details" })
  findOne(@Param("id") id: string) {
    return this.schedulesService.findOne(id);
  }

  @Patch(":id")
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "Update schedule timings" })
  update(@Param("id") id: string, @Body() dto: UpdateScheduleDto) {
    return this.schedulesService.update(id, dto);
  }

  @Delete(":id")
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: "Delete schedule" })
  remove(@Param("id") id: string) {
    return this.schedulesService.remove(id);
  }
}
