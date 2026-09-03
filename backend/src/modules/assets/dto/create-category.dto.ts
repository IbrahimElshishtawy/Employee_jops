import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  Min,
  Max,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateAssetCategoryDto {
  @ApiProperty({
    example: "IT Equipment",
    description: "Name of the asset category",
  })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: "CAT-IT-01", description: "Unique category code" })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiPropertyOptional({ example: "Laptops, monitors, networking gear" })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: 36, description: "Useful life in months" })
  @IsOptional()
  @IsNumber()
  @Min(1)
  usefulLifeMonths?: number;

  @ApiPropertyOptional({
    example: 20.0,
    description: "Annual depreciation rate percentage",
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  depreciationRate?: number;
}
