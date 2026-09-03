import {
  IsString,
  IsNotEmpty,
  IsArray,
  ValidateNested,
  IsDateString,
} from "class-validator";
import { Type } from "class-transformer";
import { ApiProperty } from "@nestjs/swagger";

export class SyncQueueItemDto {
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
}
