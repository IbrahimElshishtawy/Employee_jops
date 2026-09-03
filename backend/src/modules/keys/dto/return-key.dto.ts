import { IsOptional, IsString } from "class-validator";
import { ApiPropertyOptional } from "@nestjs/swagger";

export class ReturnKeyDto {
  @ApiPropertyOptional({ example: "Returned in good condition" })
  @IsOptional()
  @IsString()
  notes?: string;
}
