import { IsOptional, IsString, IsEnum, IsInt, Min } from "class-validator";
import { Type } from "class-transformer";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { TrainingCategory, TrainingSessionStatus } from "@prisma/client";

export class QueryTrainingCoursesDto {
  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ example: 20, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 20;

  @ApiPropertyOptional({ description: "Search by code, title" })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: TrainingCategory })
  @IsOptional()
  @IsEnum(TrainingCategory)
  category?: TrainingCategory;
}

export class QueryTrainingSessionsDto {
  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ example: 20, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 20;

  @ApiPropertyOptional({ example: "course-uuid" })
  @IsOptional()
  @IsString()
  courseId?: string;

  @ApiPropertyOptional({ enum: TrainingSessionStatus })
  @IsOptional()
  @IsEnum(TrainingSessionStatus)
  status?: TrainingSessionStatus;
}
