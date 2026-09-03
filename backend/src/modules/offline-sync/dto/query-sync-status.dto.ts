import { IsOptional, IsString, IsEnum, IsInt, Min } from "class-validator";
import { Type } from "class-transformer";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { SyncQueueStatus } from "@prisma/client";

export class QuerySyncQueueDto {
  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ example: 50, default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 50;

  @ApiPropertyOptional({ enum: SyncQueueStatus })
  @IsOptional()
  @IsEnum(SyncQueueStatus)
  status?: SyncQueueStatus;

  @ApiPropertyOptional({ example: "dev-hardware-12345" })
  @IsOptional()
  @IsString()
  deviceId?: string;
}
