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

export class CreatePurchaseOrderItemDto {
  @ApiPropertyOptional({ example: "stock-item-uuid" })
  @IsOptional()
  @IsString()
  itemId?: string;

  @ApiProperty({ example: "White Luxury Bath Towel" })
  @IsString()
  @IsNotEmpty()
  itemName: string;

  @ApiProperty({ example: 50, default: 1 })
  @IsInt()
  @Min(1)
  quantityOrdered: number;

  @ApiProperty({ example: 32.5 })
  @IsNumber()
  @Min(0)
  unitPrice: number;
}

export class CreatePurchaseOrderDto {
  @ApiPropertyOptional({ example: "pr-uuid-123" })
  @IsOptional()
  @IsString()
  purchaseRequestId?: string;

  @ApiProperty({ example: "supplier-uuid-456" })
  @IsString()
  @IsNotEmpty()
  supplierId: string;

  @ApiPropertyOptional({ example: "2026-09-20T00:00:00.000Z" })
  @IsOptional()
  @IsDateString()
  expectedDeliveryDate?: string;

  @ApiPropertyOptional({ example: "Net 30 Days" })
  @IsOptional()
  @IsString()
  paymentTerms?: string;

  @ApiPropertyOptional({ example: 243.75, default: 0, description: "VAT 15% or tax amount" })
  @IsOptional()
  @IsNumber()
  @Min(0)
  taxAmount?: number;

  @ApiPropertyOptional({ example: "Deliver to Central Receiving Dock" })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ type: [CreatePurchaseOrderItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreatePurchaseOrderItemDto)
  items: CreatePurchaseOrderItemDto[];
}
