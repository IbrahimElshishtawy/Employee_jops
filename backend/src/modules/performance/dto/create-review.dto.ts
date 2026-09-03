import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  IsDateString,
  Min,
  Max,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreatePerformanceReviewDto {
  @ApiProperty({ example: "emp-profile-uuid" })
  @IsString()
  @IsNotEmpty()
  employeeId: string;

  @ApiProperty({ example: "Annual Review 2026" })
  @IsString()
  @IsNotEmpty()
  cycleName: string;

  @ApiProperty({ example: "2026-01-01T00:00:00.000Z" })
  @IsDateString()
  periodStart: string;

  @ApiProperty({ example: "2026-12-31T23:59:59.000Z" })
  @IsDateString()
  periodEnd: string;

  @ApiProperty({ example: 4.5, description: "Overall rating out of 5.0" })
  @IsNumber()
  @Min(1.0)
  @Max(5.0)
  overallRating: number;

  @ApiPropertyOptional({ example: "Exceptional guest communication and leadership under pressure" })
  @IsOptional()
  @IsString()
  strengths?: string;

  @ApiPropertyOptional({ example: "Further training on PMS back-office night audit" })
  @IsOptional()
  @IsString()
  improvements?: string;

  @ApiPropertyOptional({ example: "Recommended for Senior Concierge promotion" })
  @IsOptional()
  @IsString()
  comments?: string;
}
