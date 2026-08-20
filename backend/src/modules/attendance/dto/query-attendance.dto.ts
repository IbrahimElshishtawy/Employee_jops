import { ApiPropertyOptional } from "@nestjs/swagger";
import { Type } from "class-transformer";
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from "class-validator";
import { AttendanceStatus } from "@prisma/client";

export class QueryAttendanceDto {
  @ApiPropertyOptional({
    description: "Filter by start date (YYYY-MM-DD)",
    example: "2026-08-01",
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    description: "Filter by end date (YYYY-MM-DD)",
    example: "2026-08-31",
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  @ApiPropertyOptional({
    description: "Filter by Year-Month (YYYY-MM)",
    example: "2026-08",
  })
  @IsOptional()
  @IsString()
  month?: string;

  @ApiPropertyOptional({
    enum: AttendanceStatus,
    description: "Filter by attendance status",
  })
  @IsOptional()
  @IsEnum(AttendanceStatus)
  status?: AttendanceStatus;

  @ApiPropertyOptional({ description: "Filter by workplace ID" })
  @IsOptional()
  @IsString()
  workplaceId?: string;

  @ApiPropertyOptional({ description: "Filter by department name" })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 30, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 30;
}
