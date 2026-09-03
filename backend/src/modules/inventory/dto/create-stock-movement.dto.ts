import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsInt,
  IsNumber,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { StockMovementType } from "@prisma/client";

export class CreateStockMovementDto {
  @ApiProperty({ example: "item-uuid" })
  @IsString()
  @IsNotEmpty()
  itemId: string;

  @ApiProperty({ example: "warehouse-uuid" })
  @IsString()
  @IsNotEmpty()
  warehouseId: string;

  @ApiProperty({ enum: StockMovementType, example: StockMovementType.RECEIVE })
  @IsEnum(StockMovementType)
  type: StockMovementType;

  @ApiProperty({ example: 25, description: "Quantity to move" })
  @IsInt()
  @Min(1)
  quantity: number;

  @ApiPropertyOptional({ example: "PURCHASE_ORDER" })
  @IsOptional()
  @IsString()
  referenceType?: string;

  @ApiPropertyOptional({ example: "po-uuid-123" })
  @IsOptional()
  @IsString()
  referenceId?: string;

  @ApiPropertyOptional({ example: "Restocked from supplier order PO-901" })
  @IsOptional()
  @IsString()
  reason?: string;

  @ApiPropertyOptional({ example: 30.0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  unitPrice?: number;
}
