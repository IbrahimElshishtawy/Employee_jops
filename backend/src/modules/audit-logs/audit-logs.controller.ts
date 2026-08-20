import { Controller, Get, Query, UseGuards } from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from "@nestjs/swagger";
import { AuditLogsService } from "./audit-logs.service";
import { PaginationQueryDto } from "../../common/dto/pagination.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { Role, AuditAction } from "@prisma/client";

@ApiTags("Audit Logs")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("audit-logs")
export class AuditLogsController {
  constructor(private readonly auditLogsService: AuditLogsService) {}

  @Get()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "List all system audit logs" })
  @ApiQuery({ name: "action", enum: AuditAction, required: false })
  @ApiQuery({ name: "entity", required: false })
  findAll(
    @Query() query: PaginationQueryDto,
    @Query("action") action?: AuditAction,
    @Query("entity") entity?: string,
  ) {
    return this.auditLogsService.findAll(query, action, entity);
  }
}
