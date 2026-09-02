import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  IsInt,
  Min,
  Max,
  IsArray,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class SubmitTaskReportDto {
  @ApiProperty({
    description: "Summary of completed work and deliverables",
    example: "Completed unit and integration tests with 100% coverage",
  })
  @IsString()
  @IsNotEmpty()
  summary: string;

  @ApiPropertyOptional({
    description: "Blockers or challenges faced during execution",
    example:
      "Encountered initial flakiness in async DB mock, resolved via transactional isolation.",
  })
  @IsOptional()
  @IsString()
  challenges?: string;

  @ApiPropertyOptional({
    description: "Total hours spent on the task",
    example: 4.5,
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  hoursSpent?: number;

  @ApiPropertyOptional({
    description: "Final reported progress percentage",
    default: 100,
    example: 100,
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  progress?: number = 100;

  @ApiPropertyOptional({
    description: "Metadata array of attached artifacts or report files",
    example: [
      {
        fileName: "test-report.pdf",
        fileUrl: "https://cyberwise.test/test-report.pdf",
      },
    ],
  })
  @IsOptional()
  @IsArray()
  attachments?: any[];
}
