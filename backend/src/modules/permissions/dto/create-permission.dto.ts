import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsEnum, IsNotEmpty, IsOptional, IsString } from "class-validator";
import { PermissionAction, PermissionSubject } from "@prisma/client";

export class CreatePermissionDto {
  @ApiProperty({
    description: "Unique permission slug identifier (e.g. employees:read)",
    example: "employees:read",
  })
  @IsString()
  @IsNotEmpty()
  slug!: string;

  @ApiProperty({
    description: "Permission action type",
    enum: PermissionAction,
    example: PermissionAction.READ,
  })
  @IsEnum(PermissionAction)
  action!: PermissionAction;

  @ApiProperty({
    description: "Target subject/resource",
    enum: PermissionSubject,
    example: PermissionSubject.EMPLOYEES,
  })
  @IsEnum(PermissionSubject)
  subject!: PermissionSubject;

  @ApiPropertyOptional({
    description: "Human-readable description of this permission",
    example: "Allows viewing employee profiles and listing",
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({
    description: "Logical module/grouping name",
    example: "employees",
  })
  @IsString()
  @IsNotEmpty()
  module!: string;
}
