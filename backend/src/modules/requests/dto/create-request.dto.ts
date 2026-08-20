import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
  MaxLength,
  IsObject,
} from "class-validator";
import { RequestType, HalfDayPeriod } from "@prisma/client";

export class CreateRequestDto {
  @ApiProperty({
    enum: RequestType,
    example: RequestType.ANNUAL_LEAVE,
    description:
      "Type of the request (Leave, Absence, Permission, Late excuse, Half day, etc.)",
  })
  @IsEnum(RequestType)
  @IsNotEmpty()
  type: RequestType;

  @ApiProperty({
    example: "2026-09-01",
    description: "Start date in YYYY-MM-DD format",
  })
  @IsDateString()
  @IsNotEmpty()
  startDate: string;

  @ApiProperty({
    example: "2026-09-05",
    description: "End date in YYYY-MM-DD format (must be >= startDate)",
  })
  @IsDateString()
  @IsNotEmpty()
  endDate: string;

  @ApiPropertyOptional({
    example: "10:00",
    description:
      "Start time in HH:mm format (required for PERMISSION, LATE_EXCUSE, EARLY_LEAVE)",
  })
  @IsOptional()
  @IsString()
  startTime?: string;

  @ApiPropertyOptional({
    example: "12:00",
    description: "End time in HH:mm format",
  })
  @IsOptional()
  @IsString()
  endTime?: string;

  @ApiPropertyOptional({
    enum: HalfDayPeriod,
    example: HalfDayPeriod.FIRST_HALF,
    description: "Period for HALF_DAY requests (FIRST_HALF or SECOND_HALF)",
  })
  @IsOptional()
  @IsEnum(HalfDayPeriod)
  halfDayPeriod?: HalfDayPeriod;

  @ApiProperty({
    example: "Annual family vacation / Personal medical appointment",
    description: "Clear reason explaining the request",
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(3, { message: "Reason must be at least 3 characters long" })
  @MaxLength(1000, { message: "Reason cannot exceed 1000 characters" })
  reason: string;

  @ApiPropertyOptional({
    example: "https://storage.cyberwise.com/attachments/medical_report.pdf",
    description: "Optional URL or reference to supporting evidence/document",
  })
  @IsOptional()
  @IsString()
  attachmentUrl?: string;

  @ApiPropertyOptional({
    example: "req_idempotency_uuid_v4_12345",
    description:
      "Optional client-generated idempotency key to prevent duplicate submissions",
  })
  @IsOptional()
  @IsString()
  idempotencyKey?: string;

  @ApiPropertyOptional({
    example: { targetAttendanceDate: "2026-09-01", estimatedHours: 2 },
    description: "Optional custom telemetry or contextual metadata",
  })
  @IsOptional()
  @IsObject()
  metadata?: Record<string, any>;
}
