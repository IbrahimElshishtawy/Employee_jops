import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsArray,
  ValidateNested,
  IsNumber,
  IsDateString,
  Min,
} from "class-validator";
import { Type } from "class-transformer";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateJournalEntryLineDto {
  @ApiProperty({ example: "account-uuid" })
  @IsString()
  @IsNotEmpty()
  accountId: string;

  @ApiPropertyOptional({ example: 1000.0, default: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  debit?: number;

  @ApiPropertyOptional({ example: 0, default: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  credit?: number;

  @ApiPropertyOptional({ example: "Payment for linen supply" })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: "dept-uuid" })
  @IsOptional()
  @IsString()
  departmentId?: string;
}

export class CreateJournalEntryDto {
  @ApiPropertyOptional({ example: "2026-09-03T00:00:00.000Z" })
  @IsOptional()
  @IsDateString()
  entryDate?: string;

  @ApiPropertyOptional({ example: "REF-INV-8910" })
  @IsOptional()
  @IsString()
  reference?: string;

  @ApiPropertyOptional({ example: "Bi-weekly supplier invoice settlement" })
  @IsOptional()
  @IsString()
  memo?: string;

  @ApiProperty({ type: [CreateJournalEntryLineDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateJournalEntryLineDto)
  lines: CreateJournalEntryLineDto[];
}
