import { IsOptional, IsString, IsEnum, IsInt, Min } from "class-validator";
import { Type } from "class-transformer";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { LostFoundStatus } from "@prisma/client";

export class QueryLostFoundDto {
  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ example: 20, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 20;

  @ApiPropertyOptional({ description: "Search by itemName, description, itemNumber, locationFound" })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: LostFoundStatus })
  @IsOptional()
  @IsEnum(LostFoundStatus)
  status?: LostFoundStatus;

  @ApiPropertyOptional({ example: "JEWELRY" })
  @IsOptional()
  @IsString()
  category?: string;
}
