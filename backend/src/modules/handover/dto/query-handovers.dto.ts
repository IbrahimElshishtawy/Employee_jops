import { IsOptional, IsEnum, IsString, IsDateString } from "class-validator";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { PaginationQueryDto } from "../../../common/dto/pagination.dto";
import { HandoverStatus } from "@prisma/client";

export class QueryHandoversDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: HandoverStatus })
  @IsOptional()
  @IsEnum(HandoverStatus)
  status?: HandoverStatus;

  @ApiPropertyOptional({ description: "Filter by Department ID" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ description: "Filter by Workplace ID" })
  @IsOptional()
  @IsString()
  workplaceId?: string;

  @ApiPropertyOptional({ description: "Filter by outgoing EmployeeProfile ID" })
  @IsOptional()
  @IsString()
  handedOverById?: string;

  @ApiPropertyOptional({ description: "Filter by receiving EmployeeProfile ID" })
  @IsOptional()
  @IsString()
  receivedById?: string;

  @ApiPropertyOptional({ description: "Filter by specific shift date (YYYY-MM-DD)" })
  @IsOptional()
  @IsDateString()
  shiftDate?: string;

  @ApiPropertyOptional({ description: "Start date range filter" })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({ description: "End date range filter" })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  @ApiPropertyOptional({ description: "Search by summary, notes, or handover number" })
  @IsOptional()
  @IsString()
  search?: string;
}
