import { IsString, IsNotEmpty, IsOptional, IsNumber, Min } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateKPIDto {
  @ApiProperty({ example: "KPI-GUEST-SAT" })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: "Guest Satisfaction Score" })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({ example: "Monthly guest review average score percentage" })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 95.0 })
  @IsNumber()
  @Min(0)
  targetValue: number;

  @ApiPropertyOptional({ example: "PERCENT", default: "PERCENT" })
  @IsOptional()
  @IsString()
  unit?: string;

  @ApiPropertyOptional({ example: "SERVICE", default: "OPERATIONAL" })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional({ example: "dept-frontoffice-uuid" })
  @IsOptional()
  @IsString()
  departmentId?: string;
}
