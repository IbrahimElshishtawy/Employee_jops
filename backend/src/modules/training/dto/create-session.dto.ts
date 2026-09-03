import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsDateString,
  IsInt,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateTrainingSessionDto {
  @ApiProperty({ example: "course-uuid" })
  @IsString()
  @IsNotEmpty()
  courseId: string;

  @ApiProperty({ example: "Captain Tariq Al-Ghamdi (Civil Defense Certified)" })
  @IsString()
  @IsNotEmpty()
  trainerName: string;

  @ApiProperty({ example: "2026-09-15T09:00:00.000Z" })
  @IsDateString()
  startDate: string;

  @ApiProperty({ example: "2026-09-15T13:00:00.000Z" })
  @IsDateString()
  endDate: string;

  @ApiPropertyOptional({ example: "Grand Ballroom A & East Assembly Point" })
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional({ example: 30, default: 25 })
  @IsOptional()
  @IsInt()
  @Min(1)
  maxParticipants?: number;
}
