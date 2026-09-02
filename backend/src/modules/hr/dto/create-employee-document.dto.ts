import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsDateString,
  IsNumber,
  IsPositive,
} from "class-validator";
import { EmployeeDocumentType } from "@prisma/client";

export class CreateEmployeeDocumentDto {
  @ApiProperty({
    enum: EmployeeDocumentType,
    example: EmployeeDocumentType.NATIONAL_ID,
    description: "Type of HR document",
  })
  @IsEnum(EmployeeDocumentType)
  @IsNotEmpty()
  documentType: EmployeeDocumentType;

  @ApiProperty({
    example: "National Identity Card",
    description: "Document title or description",
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({
    example: "29801011234567",
    description: "Document reference or identification number",
  })
  @IsString()
  @IsOptional()
  documentNumber?: string;

  @ApiPropertyOptional({
    example: "2024-01-15",
    description: "Document issue date",
  })
  @IsDateString()
  @IsOptional()
  issueDate?: string;

  @ApiPropertyOptional({
    example: "2031-01-14",
    description: "Document expiration date",
  })
  @IsDateString()
  @IsOptional()
  expiryDate?: string;

  @ApiPropertyOptional({
    example: "https://storage.cyberwise.io/docs/national_id_01.pdf",
    description: "Storage URL or object key for document",
  })
  @IsString()
  @IsOptional()
  fileUrl?: string;

  @ApiPropertyOptional({
    example: 1048576,
    description: "File size in bytes",
  })
  @IsNumber()
  @IsPositive()
  @IsOptional()
  fileSize?: number;

  @ApiPropertyOptional({
    example: "application/pdf",
    description: "MIME type of the document",
  })
  @IsString()
  @IsOptional()
  mimeType?: string;

  @ApiPropertyOptional({
    example: "Verified against original civil registry card",
    description: "Additional HR notes",
  })
  @IsString()
  @IsOptional()
  notes?: string;
}
