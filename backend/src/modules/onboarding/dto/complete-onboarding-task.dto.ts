import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsBoolean, IsNotEmpty, IsOptional, IsString } from "class-validator";

export class CompleteOnboardingTaskDto {
  @ApiProperty({
    example: true,
    description: "Mark task as completed (true) or pending (false)",
  })
  @IsBoolean()
  @IsNotEmpty()
  isCompleted: boolean;

  @ApiPropertyOptional({
    example: "Verified National ID copy physically on 2026-09-05",
    description: "Completion remarks or notes",
  })
  @IsString()
  @IsOptional()
  notes?: string;
}
