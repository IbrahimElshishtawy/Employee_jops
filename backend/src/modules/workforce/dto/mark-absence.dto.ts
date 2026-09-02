import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsArray,
  IsDateString,
  IsNotEmpty,
  IsOptional,
  IsString,
} from "class-validator";

export class MarkAbsenceDto {
  @ApiProperty({
    description: "Date of absence to record (YYYY-MM-DD)",
    example: "2026-09-02",
  })
  @IsDateString()
  @IsNotEmpty()
  date: string;

  @ApiPropertyOptional({
    description:
      "Optional specific array of employeeProfile IDs to mark absent. If omitted, all scheduled employees without check-in/leave will be evaluated.",
    example: ["emp-uuid-1", "emp-uuid-2"],
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  employeeIds?: string[];

  @ApiPropertyOptional({
    description: "Optional justification / audit note for recording absence",
    example: "System auto-absence detection for unexcused missed shift",
  })
  @IsOptional()
  @IsString()
  reason?: string;
}
