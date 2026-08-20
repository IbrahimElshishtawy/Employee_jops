import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsEnum, IsOptional, IsString, IsUUID } from "class-validator";
import { RequestStatus, RequestType } from "@prisma/client";
import { BaseReportQueryDto } from "./base-report-query.dto";

export class RequestReportQueryDto extends BaseReportQueryDto {
  @ApiPropertyOptional({
    description: "Filter by specific Employee ID",
  })
  @IsOptional()
  @IsUUID()
  employeeId?: string;

  @ApiPropertyOptional({
    description: "Filter by Department",
  })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({
    enum: RequestType,
    description: "Filter by Request Type",
  })
  @IsOptional()
  @IsEnum(RequestType)
  type?: RequestType;

  @ApiPropertyOptional({
    enum: RequestStatus,
    description: "Filter by Request Status",
  })
  @IsOptional()
  @IsEnum(RequestStatus)
  status?: RequestStatus;
}
