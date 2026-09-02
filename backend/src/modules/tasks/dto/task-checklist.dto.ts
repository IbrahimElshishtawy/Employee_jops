import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsBoolean,
  IsInt,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class AddChecklistItemDto {
  @ApiProperty({
    description: "Checklist item title",
    example: "Verify DB indexes",
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({ description: "Display order index", default: 0 })
  @IsOptional()
  @IsInt()
  orderIndex?: number;
}

export class UpdateChecklistItemDto {
  @ApiPropertyOptional({ description: "Updated title" })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({ description: "Completion state" })
  @IsOptional()
  @IsBoolean()
  isCompleted?: boolean;

  @ApiPropertyOptional({ description: "Display order index" })
  @IsOptional()
  @IsInt()
  orderIndex?: number;
}
