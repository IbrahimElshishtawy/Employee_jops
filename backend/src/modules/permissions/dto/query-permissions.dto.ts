import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsEnum, IsOptional, IsString } from "class-validator";
import { PermissionAction, PermissionSubject } from "@prisma/client";
import { PaginationQueryDto } from "../../../common/dto/pagination.dto";

export class QueryPermissionsDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    description: "Filter by module group",
    example: "payroll",
  })
  @IsOptional()
  @IsString()
  module?: string;

  @ApiPropertyOptional({
    description: "Filter by action type",
    enum: PermissionAction,
  })
  @IsOptional()
  @IsEnum(PermissionAction)
  action?: PermissionAction;

  @ApiPropertyOptional({
    description: "Filter by subject/resource",
    enum: PermissionSubject,
  })
  @IsOptional()
  @IsEnum(PermissionSubject)
  subject?: PermissionSubject;
}
