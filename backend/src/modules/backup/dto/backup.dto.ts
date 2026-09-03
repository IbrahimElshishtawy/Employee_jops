import { IsString, IsOptional, IsBoolean } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateBackupDto {
  @ApiPropertyOptional({ example: "Daily automated database snapshot" })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ example: false, default: false })
  @IsOptional()
  @IsBoolean()
  includeFiles?: boolean;
}

export class RestoreBackupDto {
  @ApiPropertyOptional({
    description: "If true, validates checksum and simulates restore without destructive writes",
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  simulateOnly?: boolean;
}
