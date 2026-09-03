import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  IsInt,
  IsDateString,
  Min,
  Max,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateGoalDto {
  @ApiProperty({ example: "emp-profile-uuid" })
  @IsString()
  @IsNotEmpty()
  employeeId: string;

  @ApiPropertyOptional({ example: "kpi-uuid" })
  @IsOptional()
  @IsString()
  kpiId?: string;

  @ApiProperty({ example: "Achieve 98% room inspection passing score" })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({ example: "Zero guest cleanliness complaints in assigned section" })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 98.0 })
  @IsNumber()
  @Min(0)
  targetValue: number;

  @ApiPropertyOptional({ example: "2026-12-31T23:59:59.000Z" })
  @IsOptional()
  @IsDateString()
  deadline?: string;

  @ApiPropertyOptional({ example: 25, default: 100 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  weight?: number;
}
