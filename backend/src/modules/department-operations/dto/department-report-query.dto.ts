import { IsBoolean, IsDateString, IsNotEmpty, IsOptional, IsString } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { Transform } from "class-transformer";

export class DepartmentReportQueryDto {
  @ApiProperty({
    description: "Department ID",
    example: "dept-eng-uuid",
  })
  @IsString()
  @IsNotEmpty()
  departmentId: string;

  @ApiProperty({
    description: "Start date (YYYY-MM-DD)",
    example: "2026-09-01",
  })
  @IsDateString()
  @IsNotEmpty()
  startDate: string;

  @ApiProperty({
    description: "End date (YYYY-MM-DD)",
    example: "2026-09-30",
  })
  @IsDateString()
  @IsNotEmpty()
  endDate: string;

  @ApiPropertyOptional({
    description: "Whether to return results formatted as CSV",
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === "true" || value === true)
  exportCsv?: boolean;
}
