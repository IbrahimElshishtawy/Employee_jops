import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateIf,
} from "class-validator";
import { WorkflowAction } from "@prisma/client";

export class ProcessApprovalDto {
  @ApiProperty({
    enum: WorkflowAction,
    example: WorkflowAction.APPROVE,
    description:
      "Approval action (APPROVE, REJECT, DELEGATE, RETURN_FOR_CORRECTION)",
  })
  @IsEnum(WorkflowAction)
  @IsNotEmpty()
  action: WorkflowAction;

  @ApiPropertyOptional({
    example:
      "Approved after reviewing team availability and project deadlines.",
    description: "Optional notes or remarks when approving",
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  comment?: string;

  @ApiPropertyOptional({
    example: "Insufficient sprint coverage during production release.",
    description: "Mandatory reason when rejecting the request",
  })
  @ValidateIf((o) => o.action === WorkflowAction.REJECT)
  @IsNotEmpty({
    message: "Rejection reason is required when rejecting a request",
  })
  @IsString()
  @MinLength(3, {
    message: "Rejection reason must be at least 3 characters long",
  })
  @MaxLength(1000)
  rejectionReason?: string;
}
