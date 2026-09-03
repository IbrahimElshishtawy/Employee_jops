import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEmail,
  IsNumber,
  Min,
  Max,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateSupplierDto {
  @ApiProperty({ example: "SUP-001" })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: "Al-Safwa Hotel Supplies LLC" })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: "Ahmed Mansour" })
  @IsOptional()
  @IsString()
  contactPerson?: string;

  @ApiPropertyOptional({ example: "sales@alsafwasupplies.com" })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: "+966501234567" })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: "King Fahd Road, Riyadh, Saudi Arabia" })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: "300123456700003" })
  @IsOptional()
  @IsString()
  taxNumber?: string;

  @ApiPropertyOptional({ example: "Net 30 Days" })
  @IsOptional()
  @IsString()
  paymentTerms?: string;

  @ApiPropertyOptional({ example: 4.8, default: 5.0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(5)
  rating?: number;
}
