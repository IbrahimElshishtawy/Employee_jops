import { IsOptional, IsInt, IsEnum, IsString, Min } from "class-validator";
import { Type } from "class-transformer";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { BudgetStatus } from "@prisma/client";

export class QueryBudgetsDto {
  @ApiPropertyOptional({ example: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ example: 20, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number = 20;

  @ApiPropertyOptional({ example: 2026 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  fiscalYear?: number;

  @ApiPropertyOptional({ enum: BudgetStatus })
  @IsOptional()
  @IsEnum(BudgetStatus)
  status?: BudgetStatus;

  @ApiPropertyOptional({ example: "dept-uuid" })
  @IsOptional()
  @IsString()
  departmentId?: string;
}
