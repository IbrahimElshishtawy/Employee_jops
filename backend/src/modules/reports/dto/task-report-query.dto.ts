import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsBoolean, IsEnum, IsOptional, IsString } from "class-validator";
import { Transform } from "class-transformer";
import { BaseReportQueryDto } from "./base-report-query.dto";
import { TaskPriority, TaskStatus } from "@prisma/client";

export class TaskReportQueryDto extends BaseReportQueryDto {
  @ApiPropertyOptional({ description: "Filter by Department ID" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ description: "Filter by assigned EmployeeProfile ID" })
  @IsOptional()
  @IsString()
  employeeId?: string;

  @ApiPropertyOptional({ description: "Filter by Workplace ID" })
  @IsOptional()
  @IsString()
  workplaceId?: string;

  @ApiPropertyOptional({ enum: TaskStatus })
  @IsOptional()
  @IsEnum(TaskStatus)
  status?: TaskStatus;

  @ApiPropertyOptional({ enum: TaskPriority })
  @IsOptional()
  @IsEnum(TaskPriority)
  priority?: TaskPriority;

  @ApiPropertyOptional({ description: "Filter overdue tasks" })
  @IsOptional()
  @Transform(({ value }) => value === "true" || value === true)
  @IsBoolean()
  isOverdue?: boolean;
}
