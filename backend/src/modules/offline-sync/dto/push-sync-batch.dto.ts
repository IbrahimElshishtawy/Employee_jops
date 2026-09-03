import {
  IsString,
  IsNotEmpty,
  IsArray,
  ValidateNested,
  IsDateString,
  IsOptional,
} from "class-validator";
import { Type } from "class-transformer";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class SyncQueueItemDto {
  @ApiPropertyOptional({ example: "act-9876-uuid-v4", description: "Unique client-generated idempotency identifier" })
  @IsOptional()
  @IsString()
  clientActionId?: string;

  @ApiPropertyOptional({ example: "task-uuid-or-id", description: "Target entity ID if mutation is an update" })
  @IsOptional()
  @IsString()
  entityId?: string;

  @ApiProperty({ example: "ServiceRequest" })
  @IsString()
  @IsNotEmpty()
  entityType: string;

  @ApiProperty({ example: "CREATE" })
  @IsString()
  @IsNotEmpty()
  action: string;

  @ApiProperty({ example: { roomNumber: "302", issue: "Leaking faucet" } })
  @IsNotEmpty()
  payload: any;

  @ApiProperty({ example: "2026-09-03T10:00:00.000Z" })
  @IsDateString()
  clientTimestamp: string;
}

export class PushSyncBatchDto {
  @ApiProperty({ type: [SyncQueueItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncQueueItemDto)
  items: SyncQueueItemDto[];

  @ApiPropertyOptional({ example: "2026-09-03T09:00:00.000Z", description: "Cursor or timestamp of last successful sync" })
  @IsOptional()
  @IsString()
  syncCursor?: string;

  @ApiPropertyOptional({ example: "2026-09-03T09:00:00.000Z", description: "Alias for syncCursor" })
  @IsOptional()
  @IsString()
  lastSyncToken?: string;
}
