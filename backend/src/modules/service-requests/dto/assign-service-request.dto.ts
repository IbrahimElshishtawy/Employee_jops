import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsDateString,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class AssignServiceRequestDto {
  @ApiProperty({
    description:
      "EmployeeProfile ID of the technician / handler being assigned",
    example: "emp-tech-101",
  })
  @IsString()
  @IsNotEmpty()
  assignedToId: string;

  @ApiPropertyOptional({
    description: "Target completion deadline",
    example: "2026-09-06T18:00:00Z",
  })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional({
    description: "Assignment notes or instructions for the technician",
    example: "Please bring replacement toner cartridge.",
  })
  @IsOptional()
  @IsString()
  notes?: string;
}
