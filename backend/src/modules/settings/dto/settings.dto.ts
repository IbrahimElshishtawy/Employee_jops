import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
} from "class-validator";
import { SettingCategory } from "@prisma/client";
import { PaginationQueryDto } from "../../common/dto/pagination.dto";

// ==========================================
// SYSTEM SETTING DTOs
// ==========================================

export class SetSystemSettingDto {
  @ApiProperty({
    description: "Setting unique key identifier",
    example: "attendance_grace_period_minutes",
  })
  @IsString()
  @IsNotEmpty()
  key!: string;

  @ApiProperty({
    description: "Setting value (can be string, number, boolean, or complex object)",
    example: 15,
  })
  @IsNotEmpty()
  value!: any;

  @ApiPropertyOptional({
    enum: SettingCategory,
    default: SettingCategory.GENERAL,
  })
  @IsOptional()
  @IsEnum(SettingCategory)
  category?: SettingCategory;

  @ApiPropertyOptional({
    description: "Whether this setting is public to clients without auth",
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  isPublic?: boolean;

  @ApiPropertyOptional({
    description: "Description of what this setting controls",
    example: "Grace period for check-in before marking lateness",
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ description: "Organization ID if tenant-specific" })
  @IsOptional()
  @IsUUID()
  organizationId?: string;
}

export class QuerySettingsDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: SettingCategory })
  @IsOptional()
  @IsEnum(SettingCategory)
  category?: SettingCategory;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  organizationId?: string;
}

// ==========================================
// FEATURE FLAG DTOs
// ==========================================

export class CreateFeatureFlagDto {
  @ApiProperty({
    description: "Unique feature flag key",
    example: "enable_biometric_face_id",
  })
  @IsString()
  @IsNotEmpty()
  key!: string;

  @ApiProperty({
    description: "Whether feature is enabled",
    default: false,
  })
  @IsBoolean()
  isEnabled!: boolean;

  @ApiPropertyOptional({
    description: "Feature description",
    example: "Enables AI biometric facial verification at check-in",
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: "Percentage rollout (0-100)",
    default: 100,
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  rolloutPercentage?: number;

  @ApiPropertyOptional({
    description: "Custom evaluation rules JSON",
  })
  @IsOptional()
  rules?: any;

  @ApiPropertyOptional({ description: "Organization ID if tenant-specific" })
  @IsOptional()
  @IsUUID()
  organizationId?: string;
}

export class UpdateFeatureFlagDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isEnabled?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  rolloutPercentage?: number;

  @ApiPropertyOptional()
  @IsOptional()
  rules?: any;
}
