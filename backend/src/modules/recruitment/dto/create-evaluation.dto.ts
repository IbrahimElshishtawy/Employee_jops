import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
  IsObject,
} from "class-validator";
import { InterviewRecommendation } from "@prisma/client";

export class CreateEvaluationDto {
  @ApiProperty({
    example: 5,
    description: "Overall evaluation score (1 to 5)",
  })
  @IsInt()
  @Min(1)
  @Max(5)
  @IsNotEmpty()
  rating: number;

  @ApiProperty({
    enum: InterviewRecommendation,
    example: InterviewRecommendation.STRONG_HIRE,
    description: "Hiring recommendation",
  })
  @IsEnum(InterviewRecommendation)
  @IsNotEmpty()
  recommendation: InterviewRecommendation;

  @ApiPropertyOptional({
    example: {
      technicalCompetence: 5,
      systemDesign: 4,
      communication: 5,
      cultureFit: 5,
    },
    description: "Structured criteria scores (key-value map)",
  })
  @IsObject()
  @IsOptional()
  criteriaScores?: Record<string, number>;

  @ApiPropertyOptional({
    example: "Exceptional mastery of NestJS, async programming, and SQL query optimization",
    description: "Key candidate strengths",
  })
  @IsString()
  @IsOptional()
  strengths?: string;

  @ApiPropertyOptional({
    example: "Limited experience with Kubernetes helm charts",
    description: "Areas for improvement / weaknesses",
  })
  @IsString()
  @IsOptional()
  weaknesses?: string;

  @ApiPropertyOptional({
    example: "Strongly recommended for the Tech Lead position",
    description: "General comments / summary",
  })
  @IsString()
  @IsOptional()
  comments?: string;
}
