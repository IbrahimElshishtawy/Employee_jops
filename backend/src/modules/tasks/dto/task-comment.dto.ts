import { IsString, IsNotEmpty, IsOptional, IsUrl } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateTaskCommentDto {
  @ApiProperty({ description: "Comment body", example: "Checklist items 1 and 2 completed." })
  @IsString()
  @IsNotEmpty()
  content: string;

  @ApiPropertyOptional({ description: "Optional attachment URL" })
  @IsOptional()
  @IsString()
  attachmentUrl?: string;
}
