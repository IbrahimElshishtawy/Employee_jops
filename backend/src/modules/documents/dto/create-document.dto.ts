import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsArray,
  IsInt,
  IsDateString,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { DocumentCategory, DocumentStatus, Role } from "@prisma/client";

export class CreateDocumentDto {
  @ApiProperty({ example: "Standard Operating Procedure: Front Desk Check-in" })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({ example: "Standard guest arrival protocol, ID verification, and payment processing" })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ enum: DocumentCategory, default: DocumentCategory.SOP })
  @IsOptional()
  @IsEnum(DocumentCategory)
  category?: DocumentCategory;

  @ApiProperty({ example: "https://storage.hotel.com/docs/sop-fd-checkin-v1.pdf" })
  @IsString()
  @IsNotEmpty()
  fileUrl: string;

  @ApiPropertyOptional({ example: "pdf", default: "pdf" })
  @IsOptional()
  @IsString()
  fileType?: string;

  @ApiPropertyOptional({ example: 1048576, default: 0, description: "File size in bytes" })
  @IsOptional()
  @IsInt()
  @Min(0)
  fileSize?: number;

  @ApiPropertyOptional({ example: "1.0", default: "1.0" })
  @IsOptional()
  @IsString()
  currentVersion?: string;

  @ApiPropertyOptional({ example: "2028-12-31T23:59:59.000Z" })
  @IsOptional()
  @IsDateString()
  expirationDate?: string;

  @ApiPropertyOptional({ example: "dept-frontoffice-uuid" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ enum: Role, isArray: true, default: [Role.SUPER_ADMIN, Role.HR_ADMIN] })
  @IsOptional()
  @IsArray()
  @IsEnum(Role, { each: true })
  accessRoles?: Role[];
}
