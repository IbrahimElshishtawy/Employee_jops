import { IsOptional, IsString } from "class-validator";
import { ApiPropertyOptional } from "@nestjs/swagger";

export class CheckOutVisitorDto {
  @ApiPropertyOptional({ example: "Badge returned, visitor escorted out" })
  @IsOptional()
  @IsString()
  remarks?: string;
}
