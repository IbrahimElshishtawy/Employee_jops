import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsEnum, IsOptional } from "class-validator";
import { AttendanceReportQueryDto } from "./attendance-report-query.dto";

export enum ExportFormat {
  CSV = "csv",
  JSON = "json",
}

export class ExportReportQueryDto extends AttendanceReportQueryDto {
  @ApiPropertyOptional({
    enum: ExportFormat,
    default: ExportFormat.CSV,
    description: "Export file format",
  })
  @IsOptional()
  @IsEnum(ExportFormat)
  format?: ExportFormat = ExportFormat.CSV;
}
