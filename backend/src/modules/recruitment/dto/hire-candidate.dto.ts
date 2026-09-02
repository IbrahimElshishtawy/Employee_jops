import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsBoolean,
  IsDateString,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  MinLength,
} from "class-validator";
import { Role } from "@prisma/client";

export class HireCandidateDto {
  @ApiProperty({
    example: "a8d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Job Application ID to hire from",
  })
  @IsUUID()
  @IsNotEmpty()
  applicationId: string;

  @ApiProperty({
    example: "b1d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Candidate ID",
  })
  @IsUUID()
  @IsNotEmpty()
  candidateId: string;

  @ApiPropertyOptional({
    example: "ahmed.hassan@company.com",
    description: "Company corporate email (defaults to candidate email if omitted)",
  })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({
    example: "TemporarySecureP@ss123",
    description: "Initial user login password",
  })
  @IsString()
  @MinLength(8)
  @IsOptional()
  password?: string;

  @ApiPropertyOptional({
    enum: Role,
    default: Role.EMPLOYEE,
    description: "System RBAC role",
  })
  @IsEnum(Role)
  @IsOptional()
  role?: Role;

  @ApiPropertyOptional({
    example: "CW-2045",
    description: "Custom employee code (auto-generated if omitted)",
  })
  @IsString()
  @IsOptional()
  employeeCode?: string;

  @ApiPropertyOptional({
    example: "a8d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Organization ID",
  })
  @IsUUID()
  @IsOptional()
  organizationId?: string;

  @ApiPropertyOptional({
    example: "b1d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Branch ID",
  })
  @IsUUID()
  @IsOptional()
  branchId?: string;

  @ApiPropertyOptional({
    example: "c2d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Department ID",
  })
  @IsUUID()
  @IsOptional()
  departmentId?: string;

  @ApiPropertyOptional({
    example: "d3d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Section ID",
  })
  @IsUUID()
  @IsOptional()
  sectionId?: string;

  @ApiPropertyOptional({
    example: "e4d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Position ID",
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
    description: "Assigned Work Schedule ID",
  })
  @IsUUID()
  @IsOptional()
  scheduleId?: string;

  @ApiPropertyOptional({
    example: "2026-10-01",
    description: "Official hire / start date",
  })
  @IsDateString()
  @IsOptional()
  hireDate?: string;

  @ApiPropertyOptional({
    example: 40000,
    description: "Base starting salary",
  })
  @IsNumber()
  @IsPositive()
  @IsOptional()
  baseSalary?: number;

  @ApiPropertyOptional({
    example: true,
    default: true,
    description: "Automatically initialize standard Onboarding checklist",
  })
  @IsBoolean()
  @IsOptional()
  initiateOnboarding?: boolean;
}
