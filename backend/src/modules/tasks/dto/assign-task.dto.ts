import { IsString, IsNotEmpty, IsOptional } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class AssignTaskDto {
  @ApiProperty({
    description: "Target EmployeeProfile ID",
    example: "emp-uuid-123",
  })
  @IsString()
  @IsNotEmpty()
  assigneeId: string;

  @ApiPropertyOptional({ description: "Assignment notes or instructions" })
  @IsOptional()
  @IsString()
  notes?: string;
}
