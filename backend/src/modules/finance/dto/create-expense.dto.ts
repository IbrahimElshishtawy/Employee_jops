import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  IsDateString,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateExpenseDto {
  @ApiProperty({ example: "OPERATING_SUPPLIES" })
  @IsString()
  @IsNotEmpty()
  category: string;

  @ApiProperty({ example: 450.0 })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiPropertyOptional({ example: "SAR", default: "SAR" })
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiPropertyOptional({ example: "2026-09-03T00:00:00.000Z" })
  @IsOptional()
  @IsDateString()
  expenseDate?: string;

  @ApiPropertyOptional({ example: "dept-uuid" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiProperty({ example: "Office Depot Saudi" })
  @IsString()
  @IsNotEmpty()
  paidTo: string;

  @ApiPropertyOptional({ example: "BANK_TRANSFER", default: "BANK_TRANSFER" })
  @IsOptional()
  @IsString()
  paymentMethod?: string;

  @ApiPropertyOptional({ example: "RCPT-10293" })
  @IsOptional()
  @IsString()
  reference?: string;

  @ApiPropertyOptional({ example: "Stationery for front desk" })
  @IsOptional()
  @IsString()
  description?: string;
}
