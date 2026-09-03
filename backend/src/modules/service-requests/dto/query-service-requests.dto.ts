import { IsOptional, IsEnum, IsString, IsDateString } from "class-validator";
import { ApiPropertyOptional } from "@nestjs/swagger";
import { PaginationQueryDto } from "../../../common/dto/pagination.dto";
import {
  ServiceRequestCategory,
  ServiceRequestPriority,
  ServiceRequestStatus,
} from "@prisma/client";

export class QueryServiceRequestsDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: ServiceRequestStatus })
  @IsOptional()
  @IsEnum(ServiceRequestStatus)
  status?: ServiceRequestStatus;

  @ApiPropertyOptional({ enum: ServiceRequestPriority })
  @IsOptional()
  @IsEnum(ServiceRequestPriority)
  priority?: ServiceRequestPriority;

  @ApiPropertyOptional({ enum: ServiceRequestCategory })
  @IsOptional()
  @IsEnum(ServiceRequestCategory)
  category?: ServiceRequestCategory;

  @ApiPropertyOptional({ description: "Filter by servicing Department ID" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({
    description: "Filter by requester EmployeeProfile ID",
  })
  @IsOptional()
  @IsString()
  requesterId?: string;

  @ApiPropertyOptional({
    description: "Filter by assigned technician EmployeeProfile ID",
  })
  @IsOptional()
  @IsString()
  assignedToId?: string;

  @ApiPropertyOptional({
    description: "Search by title, description, or request number",
  })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({
    description: "Start date filter",
    example: "2026-09-01",
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    description: "End date filter",
    example: "2026-09-30",
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;
}
