import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsArray,
  ValidateNested,
  IsInt,
  IsNumber,
  IsDateString,
  Min,
} from "class-validator";
import { Type } from "class-transformer";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreatePurchaseRequestItemDto {
  @ApiPropertyOptional({ example: "stock-item-uuid" })
  @IsOptional()
  @IsString()
  itemId?: string;

  @ApiProperty({ example: "White Luxury Bath Towel" })
  @IsString()
  @IsNotEmpty()
  itemName: string;

  @ApiPropertyOptional({ example: "Size 70x140cm" })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 50, default: 1 })
  @IsInt()
  @Min(1)
  quantity: number;

  @ApiPropertyOptional({ example: "PCS", default: "PCS" })
  @IsOptional()
  @IsString()
  unitOfMeasure?: string;

  @ApiProperty({ example: 35.0 })
  @IsNumber()
  @Min(0)
  estimatedUnitPrice: number;
}

export class CreatePurchaseRequestDto {
  @ApiProperty({ example: "dept-housekeeping-uuid" })
  @IsString()
  @IsNotEmpty()
  departmentId: string;

  @ApiPropertyOptional({ example: "HIGH", default: "MEDIUM" })
  @IsOptional()
  @IsString()
  priority?: string;

  @ApiPropertyOptional({ example: "2026-09-15T00:00:00.000Z" })
  @IsOptional()
  @IsDateString()
  requiredDate?: string;

  @ApiPropertyOptional({
    example: "Urgent restocking for upcoming holiday season",
  })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ type: [CreatePurchaseRequestItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreatePurchaseRequestItemDto)
  items: CreatePurchaseRequestItemDto[];
}
