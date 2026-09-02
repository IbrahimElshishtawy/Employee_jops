import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from "class-validator";
import { RequestType } from "@prisma/client";

export class CreateDelegationDto {
  @ApiProperty({
    example: "user-uuid-to-delegate-to",
    description: "UUID of the user being granted temporary approval authority",
  })
  @IsUUID()
  @IsNotEmpty()
  delegateId: string;

  @ApiPropertyOptional({
    enum: RequestType,
    example: RequestType.ANNUAL_LEAVE,
    description: "Scope to a specific request type or omit to delegate all request types",
  })
  @IsOptional()
  @IsEnum(RequestType)
  requestType?: RequestType;

  @ApiProperty({
    example: "2026-09-01",
    description: "Start date of the delegation period (YYYY-MM-DD)",
  })
  @IsDateString()
  @IsNotEmpty()
  startDate: string;

  @ApiProperty({
    example: "2026-09-15",
    description: "End date of the delegation period (YYYY-MM-DD, must be >= startDate)",
  })
  @IsDateString()
  @IsNotEmpty()
  endDate: string;

  @ApiPropertyOptional({
    example: "Delegating manager approval duties during annual vacation.",
    description: "Reason or context for delegation",
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
