import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from "class-validator";
import { DeductionType } from "@prisma/client";
import { PaginationQueryDto } from "../../../common/dto/pagination.dto";

export class CreateDeductionDto {
  @ApiProperty({
    example: "emp-uuid-1234",
    description: "Target Employee Profile UUID",
  })
  @IsString()
  @IsNotEmpty()
  employeeId: string;

  @ApiProperty({
    enum: DeductionType,
    example: DeductionType.PENALTY,
    description: "Type of financial deduction",
  })
  @IsEnum(DeductionType)
  @IsNotEmpty()
  type: DeductionType;

  @ApiProperty({
    example: 500,
    description: "Deduction amount (must be positive)",
  })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiProperty({
    example: "Damaged company equipment / policy non-compliance fine",
    description: "Clear justification and documentation for deduction",
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  reason: string;

  @ApiProperty({
    example: "2026-08-15",
    description: "Effective date on which deduction applies",
  })
  @IsDateString()
  @IsNotEmpty()
  effectiveDate: string;
}

export class QueryDeductionsDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    description: "Filter deductions by Employee Profile UUID",
  })
  @IsOptional()
  @IsString()
  employeeId?: string;

  @ApiPropertyOptional({
    enum: DeductionType,
    description: "Filter by deduction category",
  })
  @IsOptional()
  @IsEnum(DeductionType)
  type?: DeductionType;

  @ApiPropertyOptional({
    example: "2026-08-01",
    description: "Filter deductions on or after this date",
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    example: "2026-08-31",
    description: "Filter deductions on or before this date",
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;
}
