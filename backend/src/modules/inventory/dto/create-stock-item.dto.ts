import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  IsInt,
  IsBoolean,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateStockItemDto {
  @ApiProperty({ example: "SKU-TOWEL-WHT-L" })
  @IsString()
  @IsNotEmpty()
  sku: string;

  @ApiPropertyOptional({ example: "884920192831" })
  @IsOptional()
  @IsString()
  barcode?: string;

  @ApiProperty({ example: "White Luxury Bath Towel 70x140cm" })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: "100% Egyptian cotton, 600 GSM" })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: "stock-cat-uuid" })
  @IsString()
  @IsNotEmpty()
  categoryId: string;

  @ApiProperty({ example: "warehouse-uuid" })
  @IsString()
  @IsNotEmpty()
  warehouseId: string;

  @ApiPropertyOptional({ example: "PCS", default: "PCS" })
  @IsOptional()
  @IsString()
  unitOfMeasure?: string;

  @ApiPropertyOptional({ example: 45.0, default: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  unitPrice?: number;

  @ApiPropertyOptional({ example: 30.0, default: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  costPrice?: number;

  @ApiPropertyOptional({ example: 100, default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  quantityOnHand?: number;

  @ApiPropertyOptional({ example: 20, default: 10 })
  @IsOptional()
  @IsInt()
  @Min(0)
  minThreshold?: number;

  @ApiPropertyOptional({ example: 500, default: 500 })
  @IsOptional()
  @IsInt()
  @Min(0)
  maxThreshold?: number;

  @ApiPropertyOptional({ example: 30, default: 20 })
  @IsOptional()
  @IsInt()
  @Min(0)
  reorderLevel?: number;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
