import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsEnum, IsOptional, IsString, IsUUID } from "class-validator";
import { AttendanceStatus } from "@prisma/client";
import { BaseReportQueryDto } from "./base-report-query.dto";

export class AttendanceReportQueryDto extends BaseReportQueryDto {
  @ApiPropertyOptional({
    description: "Filter by specific Employee ID",
    example: "b5f7e7a8-1234-4567-89ab-cdef01234567",
  })
  @IsOptional()
  @IsUUID()
  employeeId?: string;

  @ApiPropertyOptional({
    description: "Filter by Department",
    example: "Engineering",
  })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({
    description: "Filter by Workplace ID",
    example: "c6e8f8b9-2345-6789-01cd-ef0123456789",
  })
  @IsOptional()
  @IsUUID()
  workplaceId?: string;

  @ApiPropertyOptional({
    enum: AttendanceStatus,
    description: "Filter by Attendance Status",
  })
  @IsOptional()
  @IsEnum(AttendanceStatus)
  status?: AttendanceStatus;

  @ApiPropertyOptional({
    description: "Filter by Schedule/Shift ID",
  })
  @IsOptional()
  @IsUUID()
  scheduleId?: string;
}
