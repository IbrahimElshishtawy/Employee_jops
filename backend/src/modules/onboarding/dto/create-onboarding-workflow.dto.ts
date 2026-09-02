import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsUUID,
} from "class-validator";
import { OnboardingStatus } from "@prisma/client";

export class CreateOnboardingWorkflowDto {
  @ApiProperty({
    example: "a8d29b2b-5867-4e94-813c-d38a065bb24c",
    description: "Employee Profile ID",
  })
  @IsUUID()
  @IsNotEmpty()
  employeeId: string;

  @ApiPropertyOptional({
    example: "2026-09-01",
    description: "Onboarding start date (defaults to today)",
  })
  @IsDateString()
  @IsOptional()
  startDate?: string;

  @ApiPropertyOptional({
    example: "2026-10-01",
    description: "Target completion date (defaults to 30 days)",
  })
  @IsDateString()
  @IsOptional()
  targetDate?: string;

  @ApiPropertyOptional({
    enum: OnboardingStatus,
    default: OnboardingStatus.PENDING,
  })
  @IsEnum(OnboardingStatus)
  @IsOptional()
  status?: OnboardingStatus;
}
