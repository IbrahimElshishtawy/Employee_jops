import { IsString, IsNotEmpty, IsOptional } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateStockCategoryDto {
  @ApiProperty({ example: "CAT-LINEN" })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: "Hotel Bedding & Linens" })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({
    example: "Sheets, pillowcases, bath towels, and bathrobes",
  })
  @IsOptional()
  @IsString()
  description?: string;
}
