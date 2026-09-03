import {
  IsOptional,
  IsEnum,
  IsNumber,
  IsString,
  Min,
} from "class-validator";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { WorkOrderStatus, MaintenancePriority } from "@prisma/client";

export class UpdateWorkOrderDto {
  @ApiPropertyOptional({ enum: WorkOrderStatus })
  @IsOptional()
  @IsEnum(WorkOrderStatus)
  status?: WorkOrderStatus;

  @ApiPropertyOptional({ enum: MaintenancePriority })
  @IsOptional()
  @IsEnum(MaintenancePriority)
  priority?: MaintenancePriority;

  @ApiPropertyOptional({ example: "emp-tech-profile-uuid" })
  @IsOptional()
  @IsString()
  technicianId?: string;

  @ApiPropertyOptional({ example: 3.0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  actualHours?: number;

  @ApiPropertyOptional({ example: 150.0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  cost?: number;

  @ApiPropertyOptional({ example: "Replacement completed and tested successfully." })
  @IsOptional()
  @IsString()
  notes?: string;
}
