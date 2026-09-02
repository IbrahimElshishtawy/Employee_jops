import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from "class-validator";
import { Type } from "class-transformer";
import { RequestType, Role, ApproverType } from "@prisma/client";

export class CreateWorkflowStepDto {
  @ApiProperty({
    example: 1,
    description: "Sequential step order index (1, 2, 3...)",
  })
  @IsInt()
  @Min(1)
  @IsNotEmpty()
  stepOrder: number;

  @ApiProperty({
    example: "Direct Manager Approval",
    description: "Descriptive label for this approval step",
  })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({
    enum: ApproverType,
    example: ApproverType.DIRECT_MANAGER,
    description:
      "Approver resolution strategy (DIRECT_MANAGER, HEAD_OF_DEPARTMENT, HEAD_OF_SECTION, SPECIFIC_ROLE, SPECIFIC_USER)",
  })
  @IsEnum(ApproverType)
  @IsNotEmpty()
  approverType: ApproverType;

  @ApiPropertyOptional({
    enum: Role,
    example: Role.HR_MANAGER,
    description: "Required when approverType is SPECIFIC_ROLE",
  })
  @IsOptional()
  @IsEnum(Role)
  role?: Role;

  @ApiPropertyOptional({
    example: "user-uuid-v4",
    description: "Required when approverType is SPECIFIC_USER",
  })
  @IsOptional()
  @IsUUID()
  specificUserId?: string;

  @ApiPropertyOptional({
    example: true,
    description: "Whether this step is strictly mandatory to approve the request",
  })
  @IsOptional()
  @IsBoolean()
  isMandatory?: boolean = true;

  @ApiPropertyOptional({
    example: true,
    description: "Whether the designated approver can delegate this step",
  })
  @IsOptional()
  @IsBoolean()
  canDelegate?: boolean = true;

  @ApiPropertyOptional({
    example: 24,
    description: "Optional SLA timeout in hours",
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  timeoutHours?: number;

  @ApiPropertyOptional({
    example: false,
    description: "Whether to auto-approve when timeout expires",
  })
  @IsOptional()
  @IsBoolean()
  autoApproveOnTimeout?: boolean = false;
}

export class CreateWorkflowDto {
  @ApiProperty({
    example: "Standard Leave Approval Workflow",
    description: "Human-readable name of the workflow",
  })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({
    example: "Two-stage approval: Direct Manager -> HR Manager",
    description: "Description of the workflow rationale",
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    enum: RequestType,
    example: RequestType.ANNUAL_LEAVE,
    description: "Specific request type or omit for general/all requests",
  })
  @IsOptional()
  @IsEnum(RequestType)
  requestType?: RequestType;

  @ApiPropertyOptional({
    example: "org-uuid-v4",
    description: "Optional organization scope",
  })
  @IsOptional()
  @IsUUID()
  organizationId?: string;

  @ApiPropertyOptional({
    example: "dept-uuid-v4",
    description: "Optional department scope for department-specific workflows",
  })
  @IsOptional()
  @IsUUID()
  departmentId?: string;

  @ApiPropertyOptional({
    enum: Role,
    example: Role.EMPLOYEE,
    description: "Optional employee role condition",
  })
  @IsOptional()
  @IsEnum(Role)
  role?: Role;

  @ApiPropertyOptional({
    example: 1,
    description: "Minimum days threshold to trigger this workflow",
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  minDays?: number;

  @ApiPropertyOptional({
    example: 14,
    description: "Maximum days threshold for this workflow",
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  maxDays?: number;

  @ApiPropertyOptional({
    example: 1000,
    description: "Minimum amount threshold (for advances or financial requests)",
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  minAmount?: number;

  @ApiPropertyOptional({
    example: 10000,
    description: "Maximum amount threshold",
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  maxAmount?: number;

  @ApiPropertyOptional({
    example: 10,
    description: "Priority weight (higher priority matches first)",
  })
  @IsOptional()
  @IsInt()
  priority?: number = 0;

  @ApiPropertyOptional({
    example: true,
    description: "Whether the workflow is active",
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean = true;

  @ApiPropertyOptional({
    example: false,
    description: "Whether this is the fallback default workflow",
  })
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean = false;

  @ApiProperty({
    type: [CreateWorkflowStepDto],
    description: "Ordered approval step definitions",
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateWorkflowStepDto)
  steps: CreateWorkflowStepDto[];
}
