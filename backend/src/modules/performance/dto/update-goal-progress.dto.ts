import { IsNumber, IsOptional, IsEnum, Min } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { GoalStatus } from "@prisma/client";

export class UpdateGoalProgressDto {
  @ApiProperty({ example: 75.5 })
  @IsNumber()
  @Min(0)
  currentValue: number;

  @ApiPropertyOptional({ enum: GoalStatus })
  @IsOptional()
  @IsEnum(GoalStatus)
  status?: GoalStatus;
}
