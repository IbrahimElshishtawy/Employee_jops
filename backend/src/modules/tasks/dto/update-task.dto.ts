import { PartialType } from "@nestjs/swagger";
import { CreateTaskDto } from "./create-task.dto";
import { IsOptional, IsInt, Min, Max } from "class-validator";
import { ApiPropertyOptional } from "@nestjs/swagger";

export class UpdateTaskDto extends PartialType(CreateTaskDto) {
  @ApiPropertyOptional({ description: "Manual progress percentage (0 - 100)", example: 75 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  progress?: number;
}
