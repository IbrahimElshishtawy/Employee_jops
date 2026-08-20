import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
} from "class-validator";
import { AttendanceStatus } from "@prisma/client";

export class ManualAttendanceDto {
  @ApiProperty({
    description: "Target employee profile ID",
    example: "uuid-employee-profile-id",
  })
  @IsString()
  @IsNotEmpty()
  employeeId: string;

  @ApiProperty({
    description: "Attendance Date (YYYY-MM-DD)",
    example: "2026-08-20",
  })
  @IsDateString()
  @IsNotEmpty()
  date: string;

  @ApiProperty({ enum: AttendanceStatus, example: AttendanceStatus.PRESENT })
  @IsEnum(AttendanceStatus)
  @IsNotEmpty()
  status: AttendanceStatus;

  @ApiPropertyOptional({
    description: "Check-in timestamp ISO string",
    example: "2026-08-20T09:00:00.000Z",
  })
  @IsOptional()
  @IsDateString()
  checkInTime?: string;

  @ApiPropertyOptional({
    description: "Check-out timestamp ISO string",
    example: "2026-08-20T17:00:00.000Z",
  })
  @IsOptional()
  @IsDateString()
  checkOutTime?: string;

  @ApiProperty({
    description:
      "Mandatory HR justification reason for manual entry/correction",
    example:
      "Biometric device offline during morning shift / field mission approved",
  })
  @IsString()
  @IsNotEmpty()
  reason: string;
}
