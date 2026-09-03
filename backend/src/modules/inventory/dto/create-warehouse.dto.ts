import { IsString, IsNotEmpty, IsOptional, IsBoolean } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateWarehouseDto {
  @ApiProperty({ example: "WH-MAIN" })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: "Central Food & Beverage Store" })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: "Basement Level B2, Sector C" })
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional({ example: "dept-uuid" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
