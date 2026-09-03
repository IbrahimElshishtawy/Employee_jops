import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateBankAccountDto {
  @ApiProperty({ example: "Al-Rajhi Bank" })
  @IsString()
  @IsNotEmpty()
  bankName: string;

  @ApiProperty({ example: "SA9820000001234567890123" })
  @IsString()
  @IsNotEmpty()
  accountNumber: string;

  @ApiPropertyOptional({ example: "SA9820000001234567890123" })
  @IsOptional()
  @IsString()
  iban?: string;

  @ApiPropertyOptional({ example: "Olaya Branch, Riyadh" })
  @IsOptional()
  @IsString()
  branchName?: string;

  @ApiPropertyOptional({ example: "SAR", default: "SAR" })
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiPropertyOptional({ example: 50000.0, default: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  openingBalance?: number;
}
