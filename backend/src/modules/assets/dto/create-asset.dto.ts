import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsNumber,
  IsDateString,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { AssetStatus } from "@prisma/client";

export class CreateAssetDto {
  @ApiProperty({ example: "AST-2026-0001", description: "Unique asset code" })
  @IsString()
  @IsNotEmpty()
  assetCode: string;

  @ApiProperty({ example: "Dell Latitude 5440", description: "Asset name" })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: "Core i7 16GB RAM Laptop" })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: "cat-uuid-123", description: "Asset Category UUID" })
  @IsString()
  @IsNotEmpty()
  categoryId: string;

  @ApiPropertyOptional({ example: "SN-987654321" })
  @IsOptional()
  @IsString()
  serialNumber?: string;

  @ApiPropertyOptional({ example: "BC-12345678" })
  @IsOptional()
  @IsString()
  barcode?: string;

  @ApiPropertyOptional({ example: "2026-01-15T00:00:00.000Z" })
  @IsOptional()
  @IsDateString()
  purchaseDate?: string;

  @ApiPropertyOptional({ example: 4500.0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  purchaseCost?: number;

  @ApiPropertyOptional({ example: "Floor 2, Room 204" })
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional({ enum: AssetStatus, default: AssetStatus.ACTIVE })
  @IsOptional()
  @IsEnum(AssetStatus)
  status?: AssetStatus;

  @ApiPropertyOptional({ example: "dept-uuid-456" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ example: "emp-profile-uuid-789" })
  @IsOptional()
  @IsString()
  assignedToId?: string;

  @ApiPropertyOptional({ example: "2028-01-15T00:00:00.000Z" })
  @IsOptional()
  @IsDateString()
  warrantyExpiry?: string;

  @ApiPropertyOptional({ example: { vendor: "Dell Inc", poNumber: "PO-991" } })
  @IsOptional()
  metadata?: any;
}
