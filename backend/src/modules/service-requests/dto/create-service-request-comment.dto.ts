import { IsBoolean, IsNotEmpty, IsOptional, IsString } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateServiceRequestCommentDto {
  @ApiProperty({
    description: "Comment or update message content",
    example: "Waiting for replacement toner cartridge from supplier.",
  })
  @IsString()
  @IsNotEmpty()
  content: string;

  @ApiPropertyOptional({
    description: "Optional URL for attachment/photo/log file",
  })
  @IsOptional()
  @IsString()
  attachmentUrl?: string;

  @ApiPropertyOptional({
    description: "Whether this comment is internal to department staff only",
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  isInternal?: boolean;
}
