import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Min,
  MinLength,
} from "class-validator";
import {
  PayrollPeriodStatus,
  PayrollRecordStatus,
  PayrollLineItemType,
} from "@prisma/client";
import { PaginationQueryDto } from "../../../common/dto/pagination.dto";

export class CreatePayrollPeriodDto {
  @ApiProperty({
    example: "2026-08",
    description: "Name of the payroll period (e.g. YYYY-MM)",
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{4}-\d{2}$/, {
    message: "Period name must be in format YYYY-MM",
  })
  name: string;

  @ApiProperty({
    example: "2026-08-01",
    description: "Start date of the payroll cycle",
  })
  @IsDateString()
  @IsNotEmpty()
  startDate: string;

  @ApiProperty({
    example: "2026-08-31",
    description: "End date of the payroll cycle",
  })
  @IsDateString()
  @IsNotEmpty()
  endDate: string;
}

export class CalculatePayrollDto {
  @ApiPropertyOptional({
    description:
      "Optional single Employee Profile UUID to calculate (if omitted, calculates entire active workforce)",
  })
  @IsOptional()
  @IsString()
  employeeId?: string;

  @ApiPropertyOptional({
    example: "Engineering",
    description: "Optional department filter for calculation",
  })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({
    example: false,
    default: false,
    description:
      "If true, recalculates already drafted records for this period",
  })
  @IsOptional()
  @IsBoolean()
  recalculate?: boolean = false;
}

export class FinalizePayrollDto {
  @ApiPropertyOptional({
    example: "Finalized and approved by CFO & HR Director for disbursement.",
    description: "Optional remarks for period finalization audit trail",
  })
  @IsOptional()
  @IsString()
  remarks?: string;

  @ApiPropertyOptional({
    example: "fin_period_idemp_key_2026_08",
    description: "Idempotency key for finalization action",
  })
  @IsOptional()
  @IsString()
  idempotencyKey?: string;
}

export class CreateAdjustmentDto {
  @ApiProperty({
    enum: PayrollLineItemType,
    example: PayrollLineItemType.BONUS,
    description:
      "Adjustment line item category (BONUS, MANUAL_DEDUCTION, OTHER_DEDUCTION, etc.)",
  })
  @IsEnum(PayrollLineItemType)
  @IsNotEmpty()
  type: PayrollLineItemType;

  @ApiProperty({
    example: 1000,
    description: "Adjustment amount (positive value)",
  })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiPropertyOptional({
    example: false,
    default: false,
    description: "Set true if this adjustment reduces net salary (deduction)",
  })
  @IsOptional()
  @IsBoolean()
  isDeduction?: boolean = false;

  @ApiProperty({
    example:
      "Post-close retroactive bonus adjustment approved by General Manager",
    description: "Mandatory reason for adjusting finalized payroll record",
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(5)
  reason: string;
}

export class QueryPayrollDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    example: "2026-08",
    description: "Filter by payroll period name (e.g. YYYY-MM)",
  })
  @IsOptional()
  @IsString()
  period?: string;

  @ApiPropertyOptional({
    description: "Filter by Payroll Period UUID",
  })
  @IsOptional()
  @IsString()
  payrollPeriodId?: string;

  @ApiPropertyOptional({
    description: "Filter by Employee Profile UUID",
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

  @ApiPropertyOptional({
    enum: PayrollRecordStatus,
    description:
      "Filter by payroll record status (DRAFT, CALCULATED, REVIEW, FINALIZED, PAID)",
  })
  @IsOptional()
  @IsEnum(PayrollRecordStatus)
  status?: PayrollRecordStatus;
}
