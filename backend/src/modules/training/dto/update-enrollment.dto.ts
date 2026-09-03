import { IsEnum, IsOptional, IsNumber, Min, Max } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { EnrollmentStatus } from "@prisma/client";

export class UpdateEnrollmentDto {
  @ApiProperty({ enum: EnrollmentStatus, example: EnrollmentStatus.COMPLETED })
  @IsEnum(EnrollmentStatus)
  status: EnrollmentStatus;

  @ApiPropertyOptional({ example: 92.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  score?: number;
}
