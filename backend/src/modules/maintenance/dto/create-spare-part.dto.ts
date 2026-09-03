import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  IsInt,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateSparePartDto {
  @ApiProperty({ example: "PART-HVAC-01" })
  @IsString()
  @IsNotEmpty()
  partNumber: string;

  @ApiProperty({ example: "Flexible Drainage Hose 1/2 inch" })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: "High durability flexible condensate pipe" })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: "HVAC" })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional({ example: "METER", default: "PCS" })
  @IsOptional()
  @IsString()
  unitOfMeasure?: string;

  @ApiPropertyOptional({ example: 25.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  unitCost?: number;

  @ApiPropertyOptional({ example: 50, default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  quantityOnHand?: number;

  @ApiPropertyOptional({ example: 10, default: 5 })
  @IsOptional()
  @IsInt()
  @Min(0)
  minQuantity?: number;
}
