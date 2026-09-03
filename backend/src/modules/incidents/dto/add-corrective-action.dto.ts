import { IsString, IsNotEmpty, IsOptional, IsDateString } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class AddCorrectiveActionDto {
  @ApiProperty({ example: "Install 4 extra caution cones at Lobby station" })
  @IsString()
  @IsNotEmpty()
  actionTitle: string;

  @ApiProperty({ example: "Procure and place bright yellow folding caution cones at each service cart" })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional({ example: "emp-profile-uuid" })
  @IsOptional()
  @IsString()
  assignedToId?: string;

  @ApiPropertyOptional({ example: "2026-09-10T18:00:00.000Z" })
  @IsOptional()
  @IsDateString()
  dueDate?: string;
}
