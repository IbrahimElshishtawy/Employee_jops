import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsOptional, IsString, IsUUID } from "class-validator";

export class UpdateEmployeeAssignmentDto {
  @ApiPropertyOptional({
    example: "a8d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Assigned Organization ID",
  })
  @IsUUID()
  @IsOptional()
  organizationId?: string;

  @ApiPropertyOptional({
    example: "b1d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Assigned Branch ID",
  })
  @IsUUID()
  @IsOptional()
  branchId?: string;

  @ApiPropertyOptional({
    example: "c2d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Assigned Department ID",
  })
  @IsUUID()
  @IsOptional()
  departmentId?: string;

  @ApiPropertyOptional({
    example: "d3d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Assigned Section ID",
  })
  @IsUUID()
  @IsOptional()
  sectionId?: string;

  @ApiPropertyOptional({
    example: "e4d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Assigned Position ID",
  })
  @IsUUID()
  @IsOptional()
  positionId?: string;

  @ApiPropertyOptional({
    example: "f5d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Direct Manager (Employee Profile ID)",
  })
  @IsUUID()
  @IsOptional()
  managerId?: string;

  @ApiPropertyOptional({
    example: "16d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Assigned Workplace ID",
  })
  @IsUUID()
  @IsOptional()
  workplaceId?: string;

  @ApiPropertyOptional({
    example: "27d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Assigned Work Schedule / Shift ID",
  })
  @IsUUID()
  @IsOptional()
  scheduleId?: string;

  @ApiPropertyOptional({
    example: "Senior Software Engineer",
    description: "Job title override/sync",
  })
  @IsString()
  @IsOptional()
  jobTitle?: string;

  @ApiPropertyOptional({
    example: "Engineering",
    description: "Department name override/sync",
  })
  @IsString()
  @IsOptional()
  department?: string;
}
