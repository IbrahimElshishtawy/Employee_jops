import { IsString, IsNotEmpty, IsOptional, IsEnum, IsBoolean } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { AccountType } from "@prisma/client";

export class CreateChartOfAccountDto {
  @ApiProperty({ example: "1010", description: "Account code" })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: "Cash and Cash Equivalents" })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ enum: AccountType, example: AccountType.ASSET })
  @IsEnum(AccountType)
  type: AccountType;

  @ApiProperty({ example: "CURRENT_ASSETS" })
  @IsString()
  @IsNotEmpty()
  category: string;

  @ApiPropertyOptional({ example: "parent-account-uuid" })
  @IsOptional()
  @IsString()
  parentId?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isHeader?: boolean;
}
