import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsDateString,
  IsBoolean,
  IsArray,
  ValidateNested,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { Type } from "class-transformer";
import { HandoverItemCategory, HandoverItemPriority } from "@prisma/client";

export class CreateHandoverItemDto {
  @ApiProperty({
    description: "Item or issue title",
    example: "Server Room A AC Unit 2 dripping water",
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({
    description: "Description or specific handover instructions",
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    enum: HandoverItemCategory,
    default: HandoverItemCategory.GENERAL,
  })
  @IsOptional()
  @IsEnum(HandoverItemCategory)
  category?: HandoverItemCategory;

  @ApiPropertyOptional({
    enum: HandoverItemPriority,
    default: HandoverItemPriority.MEDIUM,
  })
  @IsOptional()
  @IsEnum(HandoverItemPriority)
  priority?: HandoverItemPriority;

  @ApiPropertyOptional({
    description: "Linked open Task ID if applicable",
  })
  @IsOptional()
  @IsString()
  taskId?: string;

  @ApiPropertyOptional({
    description: "Linked Service Request ID if applicable",
  })
  @IsOptional()
  @IsString()
  serviceRequestId?: string;

  @ApiPropertyOptional({
    description: "Whether this item requires action from the incoming shift",
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  requiresAction?: boolean;
}

export class CreateHandoverDto {
  @ApiProperty({
    description: "Shift date (YYYY-MM-DD)",
    example: "2026-09-03",
  })
  @IsDateString()
  @IsNotEmpty()
  shiftDate: string;

  @ApiProperty({
    description: "Shift name or shift identifier",
    example: "Morning Shift (08:00 - 16:00)",
  })
  @IsString()
  @IsNotEmpty()
  shiftName: string;

  @ApiProperty({
    description: "Department ID context for the shift",
    example: "dept-ops-uuid",
  })
  @IsString()
  @IsNotEmpty()
  departmentId: string;

  @ApiPropertyOptional({
    description: "Workplace / facility location ID",
  })
  @IsOptional()
  @IsString()
  workplaceId?: string;

  @ApiPropertyOptional({
    description: "Schedule ID reference",
  })
  @IsOptional()
  @IsString()
  scheduleId?: string;

  @ApiPropertyOptional({
    description: "Designated receiving EmployeeProfile ID for next shift",
  })
  @IsOptional()
  @IsString()
  receivedById?: string;

  @ApiProperty({
    description: "Executive handover summary of current shift operations",
    example:
      "All regular duties fulfilled; 2 ongoing facility tickets transferred to evening shift.",
  })
  @IsString()
  @IsNotEmpty()
  summary: string;

  @ApiPropertyOptional({
    description: "Detailed shift operational notes, checklist or logs",
  })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({
    description:
      "Automatically collect and attach active/open tasks from department/workplace",
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  includeOpenTasks?: boolean;

  @ApiPropertyOptional({
    description: "Custom handover items, open issues, or incidents",
    type: [CreateHandoverItemDto],
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateHandoverItemDto)
  items?: CreateHandoverItemDto[];

  @ApiPropertyOptional({ description: "Custom metadata" })
  @IsOptional()
  metadata?: any;
}
