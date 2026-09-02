import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  IsInt,
  Min,
  Max,
} from "class-validator";
import { ApplicationStatus } from "@prisma/client";

export class CreateApplicationDto {
  @ApiProperty({
    example: "a8d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Job Opening ID",
  })
  @IsUUID()
  @IsNotEmpty()
  jobOpeningId: string;

  @ApiProperty({
    example: "b1d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Candidate ID",
  })
  @IsUUID()
  @IsNotEmpty()
  candidateId: string;

  @ApiPropertyOptional({
    enum: ApplicationStatus,
    default: ApplicationStatus.APPLIED,
  })
  @IsEnum(ApplicationStatus)
  @IsOptional()
  status?: ApplicationStatus;

  @ApiPropertyOptional({
    example: 4,
    description: "Recruiter initial rating (1 to 5)",
  })
  @IsInt()
  @Min(1)
  @Max(5)
  @IsOptional()
  rating?: number;

  @ApiPropertyOptional({
    example: "Candidate applied via LinkedIn recruiter outreach",
    description: "Initial stage notes",
  })
  @IsString()
  @IsOptional()
  stageNotes?: string;
}
