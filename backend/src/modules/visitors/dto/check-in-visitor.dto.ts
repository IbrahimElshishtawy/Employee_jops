import { IsString, IsNotEmpty, IsOptional } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CheckInVisitorDto {
  @ApiProperty({ example: "Michael Chang" })
  @IsString()
  @IsNotEmpty()
  fullName: string;

  @ApiProperty({ example: "+966551234567" })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiPropertyOptional({ example: "Oracle Middle East" })
  @IsOptional()
  @IsString()
  company?: string;

  @ApiPropertyOptional({ example: "P98765432" })
  @IsOptional()
  @IsString()
  nationalIdOrPassport?: string;

  @ApiProperty({ example: "Quarterly IT Infrastructure Review" })
  @IsString()
  @IsNotEmpty()
  purpose: string;

  @ApiProperty({
    example: "emp-profile-uuid",
    description: "Employee hosting the visitor",
  })
  @IsString()
  @IsNotEmpty()
  hostEmployeeId: string;

  @ApiPropertyOptional({ example: "BADGE-VIS-102" })
  @IsOptional()
  @IsString()
  badgeNumber?: string;

  @ApiPropertyOptional({
    example: "Visitor escorted to Floor 4 conference room",
  })
  @IsOptional()
  @IsString()
  remarks?: string;
}
