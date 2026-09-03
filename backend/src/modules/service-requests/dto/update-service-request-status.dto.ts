import { IsEnum, IsNotEmpty, IsOptional, IsString } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { ServiceRequestStatus } from "@prisma/client";

export class UpdateServiceRequestStatusDto {
  @ApiProperty({
    enum: ServiceRequestStatus,
    description: "New status for the service request",
    example: ServiceRequestStatus.IN_PROGRESS,
  })
  @IsEnum(ServiceRequestStatus)
  @IsNotEmpty()
  status: ServiceRequestStatus;

  @ApiPropertyOptional({
    description: "Resolution notes provided when marking COMPLETED",
    example: "Paper jam cleared, rollers cleaned and test print passed.",
  })
  @IsOptional()
  @IsString()
  resolutionNotes?: string;

  @ApiPropertyOptional({
    description: "Reason provided when REJECTING or CANCELLING",
    example: "Duplicate request already addressed under SR-2026-0012.",
  })
  @IsOptional()
  @IsString()
  reason?: string;

  @ApiPropertyOptional({
    description: "Optional transition notes or history comment",
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
