import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsInt,
  Min,
  Max,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export enum TaskReviewAction {
  APPROVE = "APPROVE",
  REJECT = "REJECT",
}

export class ReviewTaskReportDto {
  @ApiProperty({
    enum: TaskReviewAction,
    description: "Manager decision: APPROVE (completes task) or REJECT (returns to IN_PROGRESS)",
    example: TaskReviewAction.APPROVE,
  })
  @IsEnum(TaskReviewAction)
  @IsNotEmpty()
  action: TaskReviewAction;

  @ApiPropertyOptional({
    description: "Review feedback or instructions (required when rejecting)",
    example: "Work verified and approved according to QA guidelines.",
  })
  @IsOptional()
  @IsString()
  reviewNotes?: string;

  @ApiPropertyOptional({
    description: "Performance rating score (1 to 5)",
    example: 5,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  rating?: number;
}
