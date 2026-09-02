import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsEmail,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
  IsArray,
} from "class-validator";
import { CandidateSource } from "@prisma/client";

export class CreateCandidateDto {
  @ApiProperty({
    example: "Ahmed",
    description: "Candidate first name",
  })
  @IsString()
  @IsNotEmpty()
  firstName: string;

  @ApiProperty({
    example: "Hassan",
    description: "Candidate last name",
  })
  @IsString()
  @IsNotEmpty()
  lastName: string;

  @ApiProperty({
    example: "ahmed.hassan@example.com",
    description: "Candidate contact email",
  })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiPropertyOptional({
    example: "+201012345678",
    description: "Candidate contact phone number",
  })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({
    example: "Senior Software Engineer",
    description: "Candidate current job title",
  })
  @IsString()
  @IsOptional()
  currentTitle?: string;

  @ApiPropertyOptional({
    example: 6,
    description: "Total years of relevant experience",
  })
  @IsInt()
  @Min(0)
  @IsOptional()
  experienceYears?: number;

  @ApiPropertyOptional({
    enum: CandidateSource,
    default: CandidateSource.DIRECT,
  })
  @IsEnum(CandidateSource)
  @IsOptional()
  source?: CandidateSource;

  @ApiPropertyOptional({
    example: "https://storage.cyberwise.io/resumes/ahmed_hassan_cv.pdf",
    description: "Resume / CV file URL or key",
  })
  @IsString()
  @IsOptional()
  resumeUrl?: string;

  @ApiPropertyOptional({
    example: ["Node.js", "TypeScript", "NestJS", "PostgreSQL", "Docker"],
    description: "List of core skills / competencies",
  })
  @IsArray()
  @IsOptional()
  skills?: string[];

  @ApiPropertyOptional({
    example: "Strong architectural experience in fintech projects",
    description: "HR recruiter notes",
  })
  @IsString()
  @IsOptional()
  notes?: string;
}
