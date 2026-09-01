import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsBoolean,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
} from "class-validator";
import { BranchType, PositionLevel } from "@prisma/client";

// ==========================================
// ORGANIZATION DTOs
// ==========================================

export class CreateOrganizationDto {
  @ApiProperty({ example: "CyberWise Hospitality Group" })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: "CW-CORP" })
  @IsString()
  @IsNotEmpty()
  code!: string;

  @ApiPropertyOptional({ example: "https://example.com/logo.png" })
  @IsOptional()
  @IsString()
  logoUrl?: string;

  @ApiPropertyOptional({ example: "123-456-789" })
  @IsOptional()
  @IsString()
  taxNumber?: string;

  @ApiPropertyOptional({ example: "CR-987654" })
  @IsOptional()
  @IsString()
  commercialRegister?: string;

  @ApiPropertyOptional({ example: "Enterprise Hospitality & Workforce Platform" })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: "100 Innovation Boulevard" })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: "+201000000000" })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: "contact@cyberwise.com" })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: "EGP" })
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiPropertyOptional({ example: "Africa/Cairo" })
  @IsOptional()
  @IsString()
  timezone?: string;
}

export class UpdateOrganizationDto {
  @ApiPropertyOptional({ example: "CyberWise Hospitality Group LLC" })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  logoUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  taxNumber?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  commercialRegister?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  timezone?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

// ==========================================
// BRANCH / HOTEL DTOs
// ==========================================

export class CreateBranchDto {
  @ApiProperty({ description: "Parent Organization ID" })
  @IsUUID()
  organizationId!: string;

  @ApiProperty({ example: "Grand Nile Hotel & Resort" })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: "GNH-01" })
  @IsString()
  @IsNotEmpty()
  code!: string;

  @ApiPropertyOptional({ enum: BranchType, default: BranchType.BRANCH })
  @IsOptional()
  @IsEnum(BranchType)
  type?: BranchType;

  @ApiPropertyOptional({ example: "Corniche El Nile, Cairo" })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: "Cairo" })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({ example: "Egypt" })
  @IsOptional()
  @IsString()
  country?: string;

  @ApiPropertyOptional({ example: "+20220000001" })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: "cairo-branch@cyberwise.com" })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: 30.0444 })
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional({ example: 31.2357 })
  @IsOptional()
  @IsNumber()
  longitude?: number;

  @ApiPropertyOptional({ example: 150 })
  @IsOptional()
  @IsNumber()
  radiusMeters?: number;
}

export class UpdateBranchDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ enum: BranchType })
  @IsOptional()
  @IsEnum(BranchType)
  type?: BranchType;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  country?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  longitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  radiusMeters?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

// ==========================================
// DEPARTMENT DTOs
// ==========================================

export class CreateDepartmentDto {
  @ApiProperty({ description: "Parent Organization ID" })
  @IsUUID()
  organizationId!: string;

  @ApiPropertyOptional({ description: "Specific Branch ID (optional)" })
  @IsOptional()
  @IsUUID()
  branchId?: string;

  @ApiPropertyOptional({ description: "Parent Department ID for nested divisions" })
  @IsOptional()
  @IsUUID()
  parentDepartmentId?: string;

  @ApiPropertyOptional({ description: "Head of Department (EmployeeProfile ID)" })
  @IsOptional()
  @IsUUID()
  headOfDepartmentId?: string;

  @ApiProperty({ example: "Food & Beverage" })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: "FB-DEPT" })
  @IsString()
  @IsNotEmpty()
  code!: string;

  @ApiPropertyOptional({ example: "Handles kitchen, restaurants, and room service" })
  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdateDepartmentDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  branchId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  parentDepartmentId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  headOfDepartmentId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

// ==========================================
// SECTION DTOs
// ==========================================

export class CreateSectionDto {
  @ApiProperty({ description: "Parent Department ID" })
  @IsUUID()
  departmentId!: string;

  @ApiPropertyOptional({ description: "Head of Section (EmployeeProfile ID)" })
  @IsOptional()
  @IsUUID()
  headOfSectionId?: string;

  @ApiProperty({ example: "Pastry & Bakery" })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: "PASTRY-SEC" })
  @IsString()
  @IsNotEmpty()
  code!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdateSectionDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  headOfSectionId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

// ==========================================
// POSITION DTOs
// ==========================================

export class CreatePositionDto {
  @ApiProperty({ description: "Parent Organization ID" })
  @IsUUID()
  organizationId!: string;

  @ApiPropertyOptional({ description: "Department ID" })
  @IsOptional()
  @IsUUID()
  departmentId?: string;

  @ApiPropertyOptional({ description: "Section ID" })
  @IsOptional()
  @IsUUID()
  sectionId?: string;

  @ApiProperty({ example: "Executive Sous Chef" })
  @IsString()
  @IsNotEmpty()
  title!: string;

  @ApiProperty({ example: "SOUS-CHEF" })
  @IsString()
  @IsNotEmpty()
  code!: string;

  @ApiPropertyOptional({ enum: PositionLevel, default: PositionLevel.MID })
  @IsOptional()
  @IsEnum(PositionLevel)
  level?: PositionLevel;

  @ApiPropertyOptional({ example: 8000 })
  @IsOptional()
  @IsNumber()
  minSalary?: number;

  @ApiPropertyOptional({ example: 15000 })
  @IsOptional()
  @IsNumber()
  maxSalary?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdatePositionDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({ enum: PositionLevel })
  @IsOptional()
  @IsEnum(PositionLevel)
  level?: PositionLevel;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  minSalary?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  maxSalary?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  departmentId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  sectionId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
