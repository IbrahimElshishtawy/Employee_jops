import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  IsInt,
  Min,
  IsNumber,
  IsDateString,
} from "class-validator";
import { EmploymentType, JobOpeningStatus } from "@prisma/client";

export class CreateJobOpeningDto {
  @ApiProperty({
    example: "Senior Backend Engineer",
    description: "Job opening title",
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({
    example: "ENG-BE-01",
    description: "Unique job opening code",
  })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiPropertyOptional({
    example: "a8d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Organization ID",
  })
  @IsUUID()
  @IsOptional()
  organizationId?: string;

  @ApiPropertyOptional({
    example: "b1d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Branch ID",
  })
  @IsUUID()
  @IsOptional()
  branchId?: string;

  @ApiPropertyOptional({
    example: "c2d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Department ID",
  })
  @IsUUID()
  @IsOptional()
  departmentId?: string;

  @ApiPropertyOptional({
    example: "e4d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Position ID",
  })
  @IsUUID()
  @IsOptional()
  positionId?: string;

  @ApiPropertyOptional({
    example: "We are looking for a Node.js/NestJS expert...",
    description: "Detailed job description",
  })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({
    example: "5+ years NestJS, PostgreSQL, Prisma, Redis experience",
    description: "Job requirements & qualifications",
  })
  @IsString()
  @IsOptional()
  requirements?: string;

  @ApiPropertyOptional({
    enum: EmploymentType,
    default: EmploymentType.FULL_TIME,
  })
  @IsEnum(EmploymentType)
  @IsOptional()
  employmentType?: EmploymentType;

  @ApiPropertyOptional({
    enum: JobOpeningStatus,
    default: JobOpeningStatus.DRAFT,
  })
  @IsEnum(JobOpeningStatus)
  @IsOptional()
  status?: JobOpeningStatus;

  @ApiPropertyOptional({
    example: 2,
    default: 1,
  })
  @IsInt()
  @Min(1)
  @IsOptional()
  vacancies?: number;

  @ApiPropertyOptional({
    example: "2026-12-31",
  })
  @IsDateString()
  @IsOptional()
  targetDate?: string;

  @ApiPropertyOptional({
    example: 30000,
  })
  @IsNumber()
  @IsOptional()
  minSalary?: number;

  @ApiPropertyOptional({
    example: 45000,
  })
  @IsNumber()
  @IsOptional()
  maxSalary?: number;

  @ApiPropertyOptional({
    example: "EGP",
    default: "EGP",
  })
  @IsString()
  @IsOptional()
  currency?: string;
}
