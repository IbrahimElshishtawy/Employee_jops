import { ApiPropertyOptional, ApiProperty } from "@nestjs/swagger";
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from "class-validator";

export class ApproveRequestDto {
  @ApiPropertyOptional({
    example: "Approved based on departmental staffing coverage.",
    description: "Optional reviewer remarks or approval notes",
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}

export class RejectRequestDto {
  @ApiProperty({
    example: "Insufficient project coverage during sprint release window.",
    description: "Mandatory reason explaining why the request is rejected",
  })
  @IsString()
  @IsNotEmpty({ message: "Rejection reason is required" })
  @MinLength(3, {
    message: "Rejection reason must be at least 3 characters long",
  })
  @MaxLength(500, { message: "Rejection reason cannot exceed 500 characters" })
  reason: string;
}

export class CancelRequestDto {
  @ApiPropertyOptional({
    example: "Plans changed, no longer required.",
    description: "Optional reason for cancellation by the employee",
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
