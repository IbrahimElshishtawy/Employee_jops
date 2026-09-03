import { IsString, IsNotEmpty, IsOptional, IsEnum } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export enum ConflictResolutionStrategy {
  SERVER_WINS = "SERVER_WINS",
  CLIENT_WINS = "CLIENT_WINS",
  MERGE = "MERGE",
}

export class ResolveConflictDto {
  @ApiProperty({
    enum: ConflictResolutionStrategy,
    example: ConflictResolutionStrategy.CLIENT_WINS,
    description: "Resolution strategy: SERVER_WINS, CLIENT_WINS, or MERGE",
  })
  @IsEnum(ConflictResolutionStrategy)
  strategy: ConflictResolutionStrategy;

  @ApiPropertyOptional({
    description: "Explicit merged payload when using MERGE strategy",
    example: { status: "COMPLETED", resolvedAt: "2026-09-03T12:00:00.000Z" },
  })
  @IsOptional()
  resolvedPayload?: any;
}
