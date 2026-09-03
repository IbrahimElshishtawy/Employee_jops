import { IsDateString, IsNotEmpty, IsOptional, IsString } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class QueryDepartmentOperationsDto {
  @ApiProperty({
    description: "Department ID to view operational telemetry for",
    example: "dept-engineering-uuid",
  })
  @IsString()
  @IsNotEmpty()
  departmentId: string;

  @ApiPropertyOptional({
    description: "Optional specific date for shift and attendance analysis (YYYY-MM-DD)",
    example: "2026-09-03",
  })
  @IsOptional()
  @IsDateString()
  date?: string;

  @ApiPropertyOptional({
    description: "Optional workplace filter",
  })
  @IsOptional()
  @IsString()
  workplaceId?: string;
}
