import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
} from "class-validator";
import { JobOfferStatus } from "@prisma/client";

export class CreateJobOfferDto {
  @ApiProperty({
    example: "a8d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Job Application ID",
  })
  @IsUUID()
  @IsNotEmpty()
  applicationId: string;

  @ApiProperty({
    example: "b1d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Candidate ID",
  })
  @IsUUID()
  @IsNotEmpty()
  candidateId: string;

  @ApiPropertyOptional({
    example: "e4d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Target Position ID",
  })
  @IsUUID()
  @IsOptional()
  positionId?: string;

  @ApiPropertyOptional({
    example: "c2d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Target Department ID",
  })
  @IsUUID()
  @IsOptional()
  departmentId?: string;

  @ApiProperty({
    example: 40000,
    description: "Offered basic salary per month",
  })
  @IsNumber()
  @IsPositive()
  @IsNotEmpty()
  offeredSalary: number;

  @ApiPropertyOptional({
    example: "EGP",
    default: "EGP",
  })
  @IsString()
  @IsOptional()
  currency?: string;

  @ApiPropertyOptional({
    example: "Medical & Life insurance, flexible hours, annual bonus",
    description: "Benefits package overview",
  })
  @IsString()
  @IsOptional()
  benefits?: string;

  @ApiProperty({
    example: "2026-10-01",
    description: "Proposed joining date",
  })
  @IsDateString()
  @IsNotEmpty()
  proposedStartDate: string;

  @ApiPropertyOptional({
    enum: JobOfferStatus,
    default: JobOfferStatus.DRAFT,
  })
  @IsEnum(JobOfferStatus)
  @IsOptional()
  status?: JobOfferStatus;

  @ApiPropertyOptional({
    example: "Probation period of 3 months applies",
    description: "Employment terms and conditions",
  })
  @IsString()
  @IsOptional()
  terms?: string;

  @ApiPropertyOptional({
    example: "Offer approved by HR Director and VP of Engineering",
    description: "Internal HR notes",
  })
  @IsString()
  @IsOptional()
  notes?: string;
}
