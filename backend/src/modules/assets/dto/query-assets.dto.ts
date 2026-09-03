import {
  IsOptional,
  IsString,
  IsEnum,
  IsInt,
  Min,
} from "class-validator";
import { Type } from "class-transformer";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { AssetStatus } from "@prisma/client";

export class QueryAssetsDto {
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

  @ApiPropertyOptional({ description: "Search by name, assetCode, serialNumber, barcode" })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: AssetStatus })
  @IsOptional()
  @IsEnum(AssetStatus)
  status?: AssetStatus;

  @ApiPropertyOptional({ example: "cat-uuid" })
  @IsOptional()
  @IsString()
  categoryId?: string;

  @ApiPropertyOptional({ example: "dept-uuid" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ example: "emp-profile-uuid" })
  @IsOptional()
  @IsString()
  assignedToId?: string;
}
