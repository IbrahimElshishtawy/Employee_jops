import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from "class-validator";
import { AdvanceStatus } from "@prisma/client";
import { PaginationQueryDto } from "../../../common/dto/pagination.dto";

export class RequestAdvanceDto {
  @ApiProperty({
    example: 5000,
    description:
      "Requested salary advance amount (must be positive and within eligibility limits)",
  })
  @IsNumber()
  @Min(100, { message: "Advance amount must be at least 100" })
  amount: number;

  @ApiPropertyOptional({
    example: 3,
    default: 1,
    description:
      "Number of monthly installments to repay the advance (1 to 12)",
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(12)
  requestedInstallments?: number = 1;

  @ApiProperty({
    example: "Emergency home maintenance and family medical expenses",
    description: "Reason for requesting salary advance",
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(5)
  @MaxLength(1000)
  reason: string;

  @ApiPropertyOptional({
    example: "adv_idemp_key_uuid_12345",
    description: "Client idempotency key to prevent double requests",
  })
  @IsOptional()
  @IsString()
  idempotencyKey?: string;
}

export class ApproveAdvanceDto {
  @ApiPropertyOptional({
    example: 5000,
    description:
      "Final approved amount (can be adjusted by HR, defaults to requested amount)",
  })
  @IsOptional()
  @IsNumber()
  @Min(1)
  approvedAmount?: number;

  @ApiPropertyOptional({
    example: 3,
    description:
      "Final approved installment count (defaults to requested installments)",
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(12)
  installmentsCount?: number;

  @ApiPropertyOptional({
    example: "2026-09-01",
    description: "First installment due date (defaults to next monthly cycle)",
  })
  @IsOptional()
  @IsString()
  firstDueDate?: string;

  @ApiPropertyOptional({
    example: "Approved as per company salary advance policy.",
    description: "HR remarks or approval notes",
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  remarks?: string;
}

export class RejectAdvanceDto {
  @ApiProperty({
    example:
      "Active outstanding advance exists or probationary period not completed.",
    description: "Mandatory reason explaining why advance is rejected",
  })
  @IsString()
  @IsNotEmpty({ message: "Rejection reason is required" })
  @MinLength(3)
  @MaxLength(500)
  reason: string;
}

export class PayInstallmentDto {
  @ApiProperty({
    example: 1000,
    description:
      "Amount paid towards this installment (must be > 0 and <= remaining amount)",
  })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiPropertyOptional({
    example: "Paid via bank transfer / direct deposit",
    description: "Payment notes or reference",
  })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({
    example: "pay_idemp_key_123",
    description: "Idempotency key for payment transaction",
  })
  @IsOptional()
  @IsString()
  idempotencyKey?: string;
}

export class QueryAdvancesDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    enum: AdvanceStatus,
    description:
      "Filter by advance status (PENDING, APPROVED, ACTIVE, PAID, REJECTED, CANCELLED)",
  })
  @IsOptional()
  @IsEnum(AdvanceStatus)
  status?: AdvanceStatus;

  @ApiPropertyOptional({
    description: "Filter by specific employee profile ID",
  })
  @IsOptional()
  @IsString()
  employeeId?: string;

  @ApiPropertyOptional({
    description: "Filter by employee department",
  })
  @IsOptional()
  @IsString()
  department?: string;
}
