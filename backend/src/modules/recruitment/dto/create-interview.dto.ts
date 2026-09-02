import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from "class-validator";
import { InterviewStatus, InterviewType } from "@prisma/client";

export class CreateInterviewDto {
  @ApiProperty({
    example: "a8d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Job Application ID",
  })
  @IsUUID()
  @IsNotEmpty()
  applicationId: string;

  @ApiProperty({
    example: "Technical Round 1: NestJS Architecture & DB Optimization",
    description: "Interview title / subject",
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({
    enum: InterviewType,
    default: InterviewType.TECHNICAL,
  })
  @IsEnum(InterviewType)
  @IsOptional()
  interviewType?: InterviewType;

  @ApiProperty({
    example: "2026-09-10T11:00:00.000Z",
    description: "Interview scheduled date and time (ISO-8601)",
  })
  @IsDateString()
  @IsNotEmpty()
  scheduledAt: string;

  @ApiPropertyOptional({
    example: 45,
    default: 30,
    description: "Duration in minutes",
  })
  @IsInt()
  @Min(15)
  @IsOptional()
  durationMinutes?: number;

  @ApiPropertyOptional({
    example: "u1d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Assigned Interviewer User / Employee ID",
  })
  @IsString()
  @IsOptional()
  interviewerId?: string;

  @ApiPropertyOptional({
    example: "https://meet.google.com/abc-defg-hij",
    description: "Meeting URL or physical room location",
  })
  @IsString()
  @IsOptional()
  locationOrLink?: string;

  @ApiPropertyOptional({
    enum: InterviewStatus,
    default: InterviewStatus.SCHEDULED,
  })
  @IsEnum(InterviewStatus)
  @IsOptional()
  status?: InterviewStatus;

  @ApiPropertyOptional({
    example: "Focus on concurrency, caching, and clean architecture",
    description: "Initial interview notes",
  })
  @IsString()
  @IsOptional()
  feedbackNotes?: string;
}
