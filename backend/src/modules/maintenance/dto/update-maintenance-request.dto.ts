import { IsOptional, IsEnum, IsString, IsDateString } from "class-validator";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { MaintenanceRequestStatus, MaintenancePriority } from "@prisma/client";

export class UpdateMaintenanceRequestDto {
  @ApiPropertyOptional({ enum: MaintenanceRequestStatus })
  @IsOptional()
  @IsEnum(MaintenanceRequestStatus)
  status?: MaintenanceRequestStatus;

  @ApiPropertyOptional({ enum: MaintenancePriority })
  @IsOptional()
  @IsEnum(MaintenancePriority)
  priority?: MaintenancePriority;

  @ApiPropertyOptional({ example: "Resolved by replacing the drainage tube." })
  @IsOptional()
  @IsString()
  resolutionNotes?: string;

  @ApiPropertyOptional({ example: "2026-09-05T14:00:00.000Z" })
  @IsOptional()
  @IsDateString()
  scheduledDate?: string;
}
