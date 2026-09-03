import { IsOptional, IsString, IsEnum, IsInt, Min } from "class-validator";
import { Type } from "class-transformer";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { VisitorStatus } from "@prisma/client";

export class QueryVisitorsDto {
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

  @ApiPropertyOptional({ description: "Search by fullName, phone, company, badgeNumber, visitorNumber" })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ enum: VisitorStatus })
  @IsOptional()
  @IsEnum(VisitorStatus)
  status?: VisitorStatus;

  @ApiPropertyOptional({ example: "emp-host-uuid" })
  @IsOptional()
  @IsString()
  hostEmployeeId?: string;
}
