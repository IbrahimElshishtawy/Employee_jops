import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsBoolean, IsOptional, IsString, IsUUID } from "class-validator";
import { Transform } from "class-transformer";
import { PaginationQueryDto } from "../../../common/dto/pagination.dto";

export class HrEmployeeQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    description: "Filter by Organization ID",
  })
  @IsUUID()
  @IsOptional()
  organizationId?: string;

  @ApiPropertyOptional({
    description: "Filter by Branch ID",
  })
  @IsUUID()
  @IsOptional()
  branchId?: string;

  @ApiPropertyOptional({
    description: "Filter by Department ID",
  })
  @IsUUID()
  @IsOptional()
  departmentId?: string;

  @ApiPropertyOptional({
    description: "Filter by Position ID",
  })
  @IsUUID()
  @IsOptional()
  positionId?: string;

  @ApiPropertyOptional({
    description: "Filter by Workplace ID",
  })
  @IsUUID()
  @IsOptional()
  workplaceId?: string;

  @ApiPropertyOptional({
    description: "Filter by Onboarding completion status",
  })
  @IsBoolean()
  @IsOptional()
  @Transform(({ value }) => {
    if (value === "true" || value === true) return true;
    if (value === "false" || value === false) return false;
    return undefined;
  })
  isOnboarded?: boolean;

  @ApiPropertyOptional({
    description: "Filter by Profile completion status",
  })
  @IsBoolean()
  @IsOptional()
  @Transform(({ value }) => {
    if (value === "true" || value === true) return true;
    if (value === "false" || value === false) return false;
    return undefined;
  })
  isProfileComplete?: boolean;
}
