import { PartialType } from "@nestjs/swagger";
import { CreateOnboardingTaskDto } from "./create-onboarding-task.dto";

export class UpdateOnboardingTaskDto extends PartialType(
  CreateOnboardingTaskDto,
) {}
