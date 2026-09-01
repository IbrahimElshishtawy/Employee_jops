import { IsOptional, IsEnum, IsString } from "class-validator";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { AuditAction } from "@prisma/client";
import { PaginationQueryDto } from "../../../common/dto/pagination.dto";

export class QueryAuditLogsDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: AuditAction, description: "Filter by action" })
  @IsEnum(AuditAction)
  @IsOptional()
  action?: AuditAction;

  @ApiPropertyOptional({
    description:
      "Filter by entity name (e.g. EmployeeProfile, AttendanceRecord)",
  })
  @IsString()
  @IsOptional()
  entity?: string;
}
