import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsArray,
  IsDateString,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IncidentType, IncidentSeverity } from "@prisma/client";

export class CreateIncidentDto {
  @ApiProperty({ example: "Slip and Fall in Lobby Corridor" })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({
    example:
      "Guest slipped on wet marble floor where no warning sign was placed.",
  })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional({ enum: IncidentType, default: IncidentType.SAFETY })
  @IsOptional()
  @IsEnum(IncidentType)
  type?: IncidentType;

  @ApiPropertyOptional({
    enum: IncidentSeverity,
    default: IncidentSeverity.MEDIUM,
  })
  @IsOptional()
  @IsEnum(IncidentSeverity)
  severity?: IncidentSeverity;

  @ApiProperty({ example: "Main Lobby, near East Elevator Bank" })
  @IsString()
  @IsNotEmpty()
  location: string;

  @ApiPropertyOptional({ example: "2026-09-03T11:30:00.000Z" })
  @IsOptional()
  @IsDateString()
  incidentDate?: string;

  @ApiPropertyOptional({ example: "dept-security-uuid" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({
    example: ["https://storage.hotel.com/evidence/lobby-wet-floor.jpg"],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  evidenceUrls?: string[];
}
