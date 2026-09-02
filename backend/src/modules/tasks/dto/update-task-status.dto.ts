import { IsEnum, IsNotEmpty, IsOptional, IsString } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { TaskStatus } from "@prisma/client";

export class UpdateTaskStatusDto {
  @ApiProperty({
    enum: TaskStatus,
    description: "New status for the task",
    example: TaskStatus.IN_PROGRESS,
  })
  @IsEnum(TaskStatus)
  @IsNotEmpty()
  status: TaskStatus;

  @ApiPropertyOptional({
    description: "Reason or context for status transition",
    example: "Starting implementation",
  })
  @IsOptional()
  @IsString()
  reason?: string;
}
