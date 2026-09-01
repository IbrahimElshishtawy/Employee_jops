import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsArray,
  IsBoolean,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
} from "class-validator";

export class CreateRoleDto {
  @ApiProperty({
    description: "Display name of the role",
    example: "Payroll Officer",
  })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({
    description: "Unique slug identifier for the role",
    example: "payroll-officer",
  })
  @IsString()
  @IsNotEmpty()
  slug!: string;

  @ApiPropertyOptional({
    description: "Role responsibilities description",
    example: "Handles payroll calculations, adjustments, and review",
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: "Initial permission IDs or slugs to attach",
    example: ["payroll:read", "payroll:calculate"],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  permissionSlugs?: string[];

  @ApiPropertyOptional({
    description: "Optional organization ID for tenant-scoped custom role",
  })
  @IsOptional()
  @IsUUID()
  organizationId?: string;
}

export class UpdateRoleDto {
  @ApiPropertyOptional({
    description: "Updated display name",
    example: "Senior Payroll Officer",
  })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    description: "Updated description",
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: "Whether the role is active",
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class SyncRolePermissionsDto {
  @ApiProperty({
    description: "List of permission slugs or IDs to assign to this role",
    example: ["employees:read", "payroll:read", "payroll:calculate"],
  })
  @IsArray()
  @IsString({ each: true })
  permissionSlugs!: string[];
}

export class AssignUserRolesDto {
  @ApiProperty({
    description: "Target user ID",
    example: "a8e9d3c2-1b2c-3d4e-5f6a-7b8c9d0e1f2a",
  })
  @IsUUID()
  userId!: string;

  @ApiProperty({
    description: "Role slugs or IDs to assign to the user",
    example: ["hr-manager", "custom-auditor"],
  })
  @IsArray()
  @IsString({ each: true })
  roleSlugs!: string[];
}
