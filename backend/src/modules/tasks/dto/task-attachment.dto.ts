import { IsString, IsNotEmpty, IsOptional, IsInt } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateTaskAttachmentDto {
  @ApiProperty({
    description: "File name",
    example: "architecture-diagram.pdf",
  })
  @IsString()
  @IsNotEmpty()
  fileName: string;

  @ApiProperty({
    description: "File URL / storage URI",
    example: "https://storage.cyberwise.internal/tasks/att-123.pdf",
  })
  @IsString()
  @IsNotEmpty()
  fileUrl: string;

  @ApiPropertyOptional({ description: "File size in bytes", example: 1048576 })
  @IsOptional()
  @IsInt()
  fileSize?: number;

  @ApiPropertyOptional({ description: "MIME type", example: "application/pdf" })
  @IsOptional()
  @IsString()
  mimeType?: string;
}
