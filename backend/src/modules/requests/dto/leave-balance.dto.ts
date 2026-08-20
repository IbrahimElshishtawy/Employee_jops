import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  Max,
} from "class-validator";
import { RequestType } from "@prisma/client";

export class CreateLeaveBalanceDto {
  @ApiProperty({
    description: "Target Employee Profile ID",
    example: "emp-profile-uuid-1234",
  })
  @IsString()
  @IsNotEmpty()
  employeeId: string;

  @ApiProperty({
    enum: RequestType,
    example: RequestType.ANNUAL_LEAVE,
    description:
      "Leave category (e.g. ANNUAL_LEAVE, SICK_LEAVE, EMERGENCY_LEAVE)",
  })
  @IsEnum(RequestType)
  @IsNotEmpty()
  leaveType: RequestType;

  @ApiProperty({
    example: 2026,
    description: "Year for the allocation",
  })
  @IsInt()
  @Min(2020)
  @Max(2100)
  year: number;

  @ApiProperty({
    example: 21,
    description: "Total allocated leave days for the year",
  })
  @IsNumber()
  @Min(0)
  totalDays: number;
}

export class AdjustLeaveBalanceDto {
  @ApiPropertyOptional({
    example: 25,
    description: "Updated total allocated days for the year",
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  totalDays?: number;

  @ApiPropertyOptional({
    example: 2,
    description: "Direct adjustment to used days",
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  usedDays?: number;

  @ApiPropertyOptional({
    example: "Annual bonus leave adjustment (+4 days)",
    description: "Reason for balance adjustment",
  })
  @IsOptional()
  @IsString()
  reason?: string;
}
