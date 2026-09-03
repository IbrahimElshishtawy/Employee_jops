import {
  IsString,
  IsNotEmpty,
  IsOptional,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class UploadFileDto {
  @ApiProperty({
    description:
      "Original filename with extension (e.g., report.pdf, photo.jpg)",
    example: "inspection-photo.jpg",
  })
  @IsString()
  @IsNotEmpty()
  originalName: string;

  @ApiProperty({
    description: "MIME type (e.g., image/jpeg, image/png, application/pdf)",
    example: "image/jpeg",
  })
  @IsString()
  @IsNotEmpty()
  mimeType: string;

  @ApiProperty({
    description: "Base64 encoded file content",
    example: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...",
  })
  @IsString()
  @IsNotEmpty()
  base64Content: string;

  @ApiPropertyOptional({
    description:
      "Target folder category (e.g., documents, maintenance, incidents, avatars)",
    default: "general",
    example: "maintenance",
  })
  @IsOptional()
  @IsString()
  folder?: string;
}

export class UploadResultDto {
  fileId: string;
  originalName: string;
  storedFilename: string;
  fileUrl: string;
  mimeType: string;
  fileSize: number;
  checksumSha256: string;
  uploadedAt: string;
}
