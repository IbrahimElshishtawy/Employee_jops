import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsArray,
  ValidateNested,
  IsDateString,
} from "class-validator";
import { Type } from "class-transformer";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { SyncOperation } from "@prisma/client";

export class SyncQueueItemDto {
  @ApiPropertyOptional({ example: "client-temp-id" })
  @IsOptional()
  @IsString()
  entityId?: string;

  @ApiProperty({ example: "ServiceRequest" })
  @IsString()
  @IsNotEmpty()
  entityType: string;

  @ApiProperty({ enum: SyncOperation, example: SyncOperation.CREATE })
  @IsEnum(SyncOperation)
  operation: SyncOperation;

  @ApiProperty({ example: { roomNumber: "302", issue: "Leaking faucet" } })
  @IsNotEmpty()
  payload: any;

  @ApiProperty({ example: "2026-09-03T10:00:00.000Z" })
  @IsDateString()
  clientTimestamp: string;
}

export class PushSyncBatchDto {
  @ApiProperty({ example: "dev-hardware-12345" })
  @IsString()
  @IsNotEmpty()
  deviceId: string;

  @ApiProperty({ type: [SyncQueueItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncQueueItemDto)
  items: SyncQueueItemDto[];
}
