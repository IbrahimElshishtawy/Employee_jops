import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsEnum, IsOptional, IsString, IsUUID } from "class-validator";
import { DeductionType, PayrollPeriodStatus } from "@prisma/client";
import { BaseReportQueryDto } from "./base-report-query.dto";

export class PayrollReportQueryDto extends BaseReportQueryDto {
  @ApiPropertyOptional({
    description: "Filter by Payroll Period ID",
  })
  @IsOptional()
  @IsUUID()
  payrollPeriodId?: string;

  @ApiPropertyOptional({
    description: "Filter by Department",
  })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({
    description: "Filter by Workplace ID",
  })
  @IsOptional()
  @IsUUID()
  workplaceId?: string;

  @ApiPropertyOptional({
    enum: PayrollPeriodStatus,
    description: "Filter by Payroll Period Status",
  })
  @IsOptional()
  @IsEnum(PayrollPeriodStatus)
  status?: PayrollPeriodStatus;
}

export class DeductionReportQueryDto extends BaseReportQueryDto {
  @ApiPropertyOptional({
    enum: DeductionType,
    description: "Filter by Deduction Type",
  })
  @IsOptional()
  @IsEnum(DeductionType)
  type?: DeductionType;

  @ApiPropertyOptional({
    description: "Filter by Department",
  })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({
    description: "Filter by Employee ID",
  })
  @IsOptional()
  @IsUUID()
  employeeId?: string;
}

export class AdvanceReportQueryDto extends BaseReportQueryDto {
  @ApiPropertyOptional({
    description: "Filter by Department",
  })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({
    description: "Filter by Employee ID",
  })
  @IsOptional()
  @IsUUID()
  employeeId?: string;
}
