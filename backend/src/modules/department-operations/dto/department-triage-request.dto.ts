import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsDateString,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { ServiceRequestPriority } from "@prisma/client";

export class DepartmentTriageRequestDto {
  @ApiProperty({
    description: "Service Request ID to triage",
    example: "sr-uuid-1",
  })
  @IsString()
  @IsNotEmpty()
  serviceRequestId: string;

  @ApiProperty({
    description: "Assigned technician EmployeeProfile ID",
    example: "emp-tech-1",
  })
  @IsString()
  @IsNotEmpty()
  assignedToId: string;

  @ApiPropertyOptional({
    enum: ServiceRequestPriority,
    description: "Updated priority if escalated or de-escalated",
  })
  @IsOptional()
  @IsEnum(ServiceRequestPriority)
  priority?: ServiceRequestPriority;

  @ApiPropertyOptional({
    description: "Target deadline / due date",
    example: "2026-09-04T18:00:00Z",
  })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional({
    description: "Triage notes or instructions for the technician",
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
