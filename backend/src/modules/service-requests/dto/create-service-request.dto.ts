import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsDateString,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { ServiceRequestCategory, ServiceRequestPriority } from "@prisma/client";

export class CreateServiceRequestDto {
  @ApiProperty({
    description: "Service request title",
    example: "Printer malfunctioning in 3rd Floor Finance Room",
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({
    description: "Detailed description of the issue or requested service",
    example: "The HP LaserJet printer shows paper jam and red error code 50.4.",
  })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional({
    enum: ServiceRequestCategory,
    default: ServiceRequestCategory.GENERAL,
    description: "Category of service request",
  })
  @IsOptional()
  @IsEnum(ServiceRequestCategory)
  category?: ServiceRequestCategory;

  @ApiPropertyOptional({
    enum: ServiceRequestPriority,
    default: ServiceRequestPriority.MEDIUM,
    description: "Priority of the request",
  })
  @IsOptional()
  @IsEnum(ServiceRequestPriority)
  priority?: ServiceRequestPriority;

  @ApiProperty({
    description: "Target department handling the service (e.g. IT, Maintenance)",
    example: "dept-it-uuid",
  })
  @IsString()
  @IsNotEmpty()
  departmentId: string;

  @ApiPropertyOptional({
    description: "Physical location/office/room where service is needed",
    example: "Floor 3, Office 302",
  })
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional({
    description: "Target due date/deadline for completion",
    example: "2026-09-05T17:00:00Z",
  })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional({
    description: "Optional metadata, tags, asset IDs or custom client data",
  })
  @IsOptional()
  metadata?: any;
}
