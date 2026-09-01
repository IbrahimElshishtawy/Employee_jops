import {
  IsString,
  IsOptional,
  IsArray,
  IsInt,
  IsBoolean,
  Matches,
  ArrayMinSize,
  Min,
  Max,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional, PartialType } from "@nestjs/swagger";

export class CreateScheduleDto {
  @ApiProperty({ example: "Standard Morning Shift" })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: "Regular 9 to 5 working shift" })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({
    example: "c7b5f92a-3e81-49a6-8c54-1b1e9d123456",
    description: "Assigned Workplace ID",
  })
  @IsString()
  @IsOptional()
  workplaceId?: string;

  @ApiProperty({ example: "09:00", description: "HH:mm format" })
  @IsString()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, {
    message: "startTime must be in HH:mm format",
  })
  startTime: string;

  @ApiProperty({ example: "17:00", description: "HH:mm format" })
  @IsString()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, {
    message: "endTime must be in HH:mm format",
  })
  endTime: string;

  @ApiPropertyOptional({ example: 15, default: 15 })
  @IsInt()
  @Min(0)
  @Max(120)
  @IsOptional()
  graceMinutesCheckIn?: number = 15;

  @ApiPropertyOptional({ example: 15, default: 15 })
  @IsInt()
  @Min(0)
  @Max(120)
  @IsOptional()
  graceMinutesCheckOut?: number = 15;

  @ApiProperty({
    example: [0, 1, 2, 3, 4],
    description: "Array of day numbers: 0=Sun, 1=Mon, ..., 6=Sat",
  })
  @IsArray()
  @ArrayMinSize(1)
  @IsInt({ each: true })
  workingDays: number[];

  @ApiPropertyOptional({ example: false, default: false })
  @IsBoolean()
  @IsOptional()
  isDefault?: boolean = false;
}

export class UpdateScheduleDto extends PartialType(CreateScheduleDto) {}
