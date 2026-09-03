import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsDateString,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { MaintenanceType, MaintenancePriority } from "@prisma/client";

export class CreateMaintenanceRequestDto {
  @ApiProperty({ example: "AC leaking in Executive Suite 401" })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: "Water dripping from the indoor unit onto the carpet" })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional({ enum: MaintenanceType, default: MaintenanceType.CORRECTIVE })
  @IsOptional()
  @IsEnum(MaintenanceType)
  type?: MaintenanceType;

  @ApiPropertyOptional({ enum: MaintenancePriority, default: MaintenancePriority.MEDIUM })
  @IsOptional()
  @IsEnum(MaintenancePriority)
  priority?: MaintenancePriority;

  @ApiPropertyOptional({ example: "ast-uuid-123", description: "Optional Asset ID" })
  @IsOptional()
  @IsString()
  assetId?: string;

  @ApiProperty({ example: "dept-engineering-uuid", description: "Target servicing department (Engineering)" })
  @IsString()
  @IsNotEmpty()
  departmentId: string;

  @ApiPropertyOptional({ example: "2026-09-04T10:00:00.000Z" })
  @IsOptional()
  @IsDateString()
  scheduledDate?: string;
}
