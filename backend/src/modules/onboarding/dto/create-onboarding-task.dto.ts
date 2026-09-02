import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from "class-validator";
import { OnboardingTaskCategory } from "@prisma/client";

export class CreateOnboardingTaskDto {
  @ApiProperty({
    example: "a8d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Onboarding Workflow ID",
  })
  @IsUUID()
  @IsNotEmpty()
  workflowId: string;

  @ApiProperty({
    example: "Submit National ID Copy",
    description: "Task title",
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({
    example: "Provide front and back scan of valid national identity card",
    description: "Detailed instructions for the task",
  })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({
    enum: OnboardingTaskCategory,
    default: OnboardingTaskCategory.DOCUMENTATION,
  })
  @IsEnum(OnboardingTaskCategory)
  @IsOptional()
  category?: OnboardingTaskCategory;

  @ApiPropertyOptional({
    example: true,
    default: true,
  })
  @IsBoolean()
  @IsOptional()
  isMandatory?: boolean;

  @ApiPropertyOptional({
    example: "u1d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Specific assigned HR / IT User ID",
  })
  @IsString()
  @IsOptional()
  assignedToUserId?: string;

  @ApiPropertyOptional({
    example: "2026-09-15",
    description: "Task due date",
  })
  @IsDateString()
  @IsOptional()
  dueDate?: string;

  @ApiPropertyOptional({
    example: 1,
    default: 0,
  })
  @IsInt()
  @Min(0)
  @IsOptional()
  orderIndex?: number;

  @ApiPropertyOptional({
    example: "Must be reviewed by HR compliance officer",
  })
  @IsString()
  @IsOptional()
  notes?: string;
}
