import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  IsDateString,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateRevenueDto {
  @ApiProperty({ example: "ROOM_SALES" })
  @IsString()
  @IsNotEmpty()
  category: string;

  @ApiProperty({ example: 12500.0 })
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
  revenueDate?: string;

  @ApiPropertyOptional({ example: "dept-frontoffice-uuid" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiProperty({ example: "Daily Front Desk POS Settled Income" })
  @IsString()
  @IsNotEmpty()
  receivedFrom: string;

  @ApiPropertyOptional({ example: "CREDIT_CARD", default: "BANK_TRANSFER" })
  @IsOptional()
  @IsString()
  paymentMethod?: string;

  @ApiPropertyOptional({ example: "BATCH-POS-991" })
  @IsOptional()
  @IsString()
  reference?: string;

  @ApiPropertyOptional({ example: "Daily revenue close for 3rd Sept 2026" })
  @IsOptional()
  @IsString()
  description?: string;
}
