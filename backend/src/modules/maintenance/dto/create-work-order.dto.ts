import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsNumber,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { MaintenancePriority, WorkOrderStatus } from "@prisma/client";

export class CreateWorkOrderDto {
  @ApiPropertyOptional({ example: "maint-req-uuid" })
  @IsOptional()
  @IsString()
  maintenanceRequestId?: string;

  @ApiProperty({ example: "Repair HVAC Unit in Suite 401" })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: "Inspect compressor, replace drainage pipe, clean filter" })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional({ enum: MaintenancePriority, default: MaintenancePriority.MEDIUM })
  @IsOptional()
  @IsEnum(MaintenancePriority)
  priority?: MaintenancePriority;

  @ApiPropertyOptional({ enum: WorkOrderStatus, default: WorkOrderStatus.PENDING })
  @IsOptional()
  @IsEnum(WorkOrderStatus)
  status?: WorkOrderStatus;

  @ApiPropertyOptional({ example: "emp-tech-profile-uuid" })
  @IsOptional()
  @IsString()
  technicianId?: string;

  @ApiPropertyOptional({ example: 2.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  estimatedHours?: number;

  @ApiPropertyOptional({ example: "Requires ladder and vacuum drain pump" })
  @IsOptional()
  @IsString()
  notes?: string;
}
