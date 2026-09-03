import { IsString, IsNotEmpty, IsOptional } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateStockCountDto {
  @ApiProperty({ example: "warehouse-uuid" })
  @IsString()
  @IsNotEmpty()
  warehouseId: string;

  @ApiPropertyOptional({ example: "Annual physical inventory count Q3" })
  @IsOptional()
  @IsString()
  notes?: string;
}
