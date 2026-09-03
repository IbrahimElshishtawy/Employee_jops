import { IsOptional, IsString, IsEnum, IsInt, Min } from "class-validator";
import { Type } from "class-transformer";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { KeyType, KeyStatus } from "@prisma/client";

export class QueryKeysDto {
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

  @ApiPropertyOptional({ description: "Search by keyCode, name, location" })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: KeyType })
  @IsOptional()
  @IsEnum(KeyType)
  keyType?: KeyType;

  @ApiPropertyOptional({ enum: KeyStatus })
  @IsOptional()
  @IsEnum(KeyStatus)
  status?: KeyStatus;
}
