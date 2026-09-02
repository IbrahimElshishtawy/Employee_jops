import { ApiPropertyOptional, PartialType } from "@nestjs/swagger";
import { CreateOnboardingWorkflowDto } from "./create-onboarding-workflow.dto";
import { IsDateString, IsOptional } from "class-validator";

export class UpdateOnboardingWorkflowDto extends PartialType(
  CreateOnboardingWorkflowDto,
) {
  @ApiPropertyOptional({
    example: "2026-09-20T14:30:00.000Z",
    description: "Actual completion timestamp",
  })
  @IsDateString()
  @IsOptional()
  completedAt?: string;
}
