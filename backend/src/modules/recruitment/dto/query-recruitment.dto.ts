import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsEnum, IsOptional, IsString, IsUUID } from "class-validator";
import { PaginationQueryDto } from "../../../common/dto/pagination.dto";
import {
  ApplicationStatus,
  CandidateSource,
  InterviewStatus,
  JobOfferStatus,
  JobOpeningStatus,
} from "@prisma/client";

export class QueryJobOpeningsDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: JobOpeningStatus })
  @IsEnum(JobOpeningStatus)
  @IsOptional()
  status?: JobOpeningStatus;

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  departmentId?: string;

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  positionId?: string;

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  organizationId?: string;
}

export class QueryCandidatesDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: CandidateSource })
  @IsEnum(CandidateSource)
  @IsOptional()
  source?: CandidateSource;
}

export class QueryApplicationsDto extends PaginationQueryDto {
  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  jobOpeningId?: string;

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  candidateId?: string;

  @ApiPropertyOptional({ enum: ApplicationStatus })
  @IsEnum(ApplicationStatus)
  @IsOptional()
  status?: ApplicationStatus;
}

export class QueryInterviewsDto extends PaginationQueryDto {
  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  applicationId?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  interviewerId?: string;

  @ApiPropertyOptional({ enum: InterviewStatus })
  @IsEnum(InterviewStatus)
  @IsOptional()
  status?: InterviewStatus;
}

export class QueryJobOffersDto extends PaginationQueryDto {
  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  applicationId?: string;

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  candidateId?: string;

  @ApiPropertyOptional({ enum: JobOfferStatus })
  @IsEnum(JobOfferStatus)
  @IsOptional()
  status?: JobOfferStatus;
}
