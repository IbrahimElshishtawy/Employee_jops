import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsEnum, IsInt, IsOptional, IsString, Max, Min } from "class-validator";
import { ApplicationStatus } from "@prisma/client";

export class UpdateApplicationDto {
  @ApiPropertyOptional({
    enum: ApplicationStatus,
    description: "Application stage / status",
  })
  @IsEnum(ApplicationStatus)
  @IsOptional()
  status?: ApplicationStatus;

  @ApiPropertyOptional({
    example: 5,
    description: "Rating (1 to 5)",
  })
  @IsInt()
  @Min(1)
  @Max(5)
  @IsOptional()
  rating?: number;

  @ApiPropertyOptional({
    example: "Moved to technical round after initial screening",
    description: "Stage notes / progress remarks",
  })
  @IsString()
  @IsOptional()
  stageNotes?: string;

  @ApiPropertyOptional({
    example: "Failed system design interview",
    description: "Rejection rationale if rejected",
  })
  @IsString()
  @IsOptional()
  rejectionReason?: string;
}
