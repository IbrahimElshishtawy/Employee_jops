import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsArray,
  IsDateString,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateLostFoundItemDto {
  @ApiProperty({ example: "Gold Rolex Watch" })
  @IsString()
  @IsNotEmpty()
  itemName: string;

  @ApiProperty({ example: "Oyster Perpetual with silver dial found near pool lounger" })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional({ example: "JEWELRY", default: "GENERAL" })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiProperty({ example: "Outdoor Pool Area, Cabana 4" })
  @IsString()
  @IsNotEmpty()
  locationFound: string;

  @ApiPropertyOptional({ example: "2026-09-03T10:15:00.000Z" })
  @IsOptional()
  @IsDateString()
  foundDate?: string;

  @ApiProperty({ example: "Security Safe #3, Box A" })
  @IsString()
  @IsNotEmpty()
  storageLocation: string;

  @ApiPropertyOptional({ example: ["https://storage.hotel.com/lostfound/watch.jpg"] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];
}
