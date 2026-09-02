import { IsOptional, IsString, IsDateString } from "class-validator";
import { ApiPropertyOptional } from "@nestjs/swagger";

export class QueryWorkloadDto {
  @ApiPropertyOptional({ description: "Department ID filter" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ description: "Workplace ID filter" })
  @IsOptional()
  @IsString()
  workplaceId?: string;

  @ApiPropertyOptional({ description: "Filter from date" })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({ description: "Filter to date" })
  @IsOptional()
  @IsDateString()
  endDate?: string;
}
