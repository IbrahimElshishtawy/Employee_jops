import { IsString, IsNotEmpty, IsOptional } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class LogKeyAccessDto {
  @ApiProperty({ example: "DOOR_OPENED", description: "Action taken (e.g. DOOR_OPENED, SWIPED, AUDIT)" })
  @IsString()
  @IsNotEmpty()
  action: string;

  @ApiProperty({ example: "emp-profile-uuid" })
  @IsString()
  @IsNotEmpty()
  employeeId: string;

  @ApiPropertyOptional({ example: "Accessed room 401 for room service" })
  @IsOptional()
  @IsString()
  notes?: string;
}
