import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsInt,
  IsArray,
  ValidateNested,
  IsNumber,
  IsDateString,
  Min,
} from "class-validator";
import { Type } from "class-transformer";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { BudgetPeriodType, BudgetStatus } from "@prisma/client";

export class CreateBudgetLineDto {
  @ApiProperty({ example: "OPERATING_SUPPLIES" })
  @IsString()
  @IsNotEmpty()
  category: string;

  @ApiProperty({ example: 100000.0 })
  @IsNumber()
  @Min(0)
  allocatedAmount: number;

  @ApiPropertyOptional({ example: "Linen, cleaning chemicals, guest amenities" })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class CreateBudgetDto {
  @ApiProperty({ example: "BUD-2026-HK" })
  @IsString()
  @IsNotEmpty()
  budgetCode: string;

  @ApiProperty({ example: "Housekeeping Annual Operating Budget 2026" })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: 2026 })
  @IsInt()
  fiscalYear: number;

  @ApiPropertyOptional({ enum: BudgetPeriodType, default: BudgetPeriodType.ANNUAL })
  @IsOptional()
  @IsEnum(BudgetPeriodType)
  periodType?: BudgetPeriodType;

  @ApiProperty({ example: "2026-01-01T00:00:00.000Z" })
  @IsDateString()
  startDate: string;

  @ApiProperty({ example: "2026-12-31T23:59:59.999Z" })
  @IsDateString()
  endDate: string;

  @ApiPropertyOptional({ example: "dept-housekeeping-uuid" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ enum: BudgetStatus, default: BudgetStatus.DRAFT })
  @IsOptional()
  @IsEnum(BudgetStatus)
  status?: BudgetStatus;

  @ApiPropertyOptional({ example: "Approved in Board meeting Jan 2026" })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ type: [CreateBudgetLineDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateBudgetLineDto)
  lines: CreateBudgetLineDto[];
}
