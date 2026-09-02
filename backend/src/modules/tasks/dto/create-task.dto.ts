import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsDateString,
  IsArray,
  ValidateNested,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { Type } from "class-transformer";
import { TaskPriority } from "@prisma/client";

export class CreateChecklistItemDto {
  @ApiProperty({ description: "Checklist item title", example: "Review API specifications" })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({ description: "Order index", example: 0 })
  @IsOptional()
  orderIndex?: number;
}

export class CreateTaskDto {
  @ApiProperty({ description: "Task title", example: "Implement Phase 5 Tasks & Reports" })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({ description: "Detailed task description" })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ enum: TaskPriority, default: TaskPriority.MEDIUM })
  @IsOptional()
  @IsEnum(TaskPriority)
  priority?: TaskPriority;

  @ApiPropertyOptional({ description: "Target EmployeeProfile ID" })
  @IsOptional()
  @IsString()
  assigneeId?: string;

  @ApiPropertyOptional({ description: "Department ID context" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ description: "Workplace ID context" })
  @IsOptional()
  @IsString()
  workplaceId?: string;

  @ApiPropertyOptional({ description: "Start date", example: "2026-09-03T09:00:00Z" })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({ description: "Due date", example: "2026-09-10T18:00:00Z" })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional({
    description: "Initial checklist items",
    type: [CreateChecklistItemDto],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateChecklistItemDto)
  checklist?: CreateChecklistItemDto[];

  @ApiPropertyOptional({ description: "Custom metadata / tags" })
  @IsOptional()
  metadata?: any;
}
