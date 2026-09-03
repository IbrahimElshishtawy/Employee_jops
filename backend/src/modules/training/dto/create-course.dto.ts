import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsBoolean,
  IsNumber,
  IsInt,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { TrainingCategory } from "@prisma/client";

export class CreateTrainingCourseDto {
  @ApiProperty({ example: "CRS-FIRE-01" })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: "Hotel Fire Safety & Evacuation Certification" })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({
    example:
      "Comprehensive hands-on fire extinguisher drill and building emergency evacuation",
  })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional({
    enum: TrainingCategory,
    default: TrainingCategory.SAFETY,
  })
  @IsOptional()
  @IsEnum(TrainingCategory)
  category?: TrainingCategory;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isMandatory?: boolean;

  @ApiProperty({ example: 4.0, description: "Duration in hours" })
  @IsNumber()
  @Min(0.5)
  durationHours: number;

  @ApiPropertyOptional({
    example: 12,
    description: "Certificate validity in months",
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  validityMonths?: number;
}
