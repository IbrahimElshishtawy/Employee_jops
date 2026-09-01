import { Controller, Get, Query, UseGuards } from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { AuditLogsService } from "./audit-logs.service";
import { QueryAuditLogsDto } from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { Role } from "@prisma/client";

@ApiTags("Audit Logs")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller("audit-logs")
export class AuditLogsController {
  constructor(private readonly auditLogsService: AuditLogsService) {}

  @Get()
  @Roles(Role.SUPER_ADMIN, Role.HR_ADMIN)
  @ApiOperation({ summary: "List all system audit logs" })
  findAll(@Query() query: QueryAuditLogsDto) {
    return this.auditLogsService.findAll(query, query.action, query.entity);
  }
}

