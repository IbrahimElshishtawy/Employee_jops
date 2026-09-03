import { IsString, IsNotEmpty, IsOptional, IsDateString } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class IssueCertificateDto {
  @ApiProperty({ example: "emp-profile-uuid" })
  @IsString()
  @IsNotEmpty()
  employeeId: string;

  @ApiPropertyOptional({ example: "course-uuid" })
  @IsOptional()
  @IsString()
  courseId?: string;

  @ApiProperty({ example: "Certified Fire Safety & Evacuation Specialist" })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({ example: "2027-09-15T00:00:00.000Z" })
  @IsOptional()
  @IsDateString()
  expiryDate?: string;

  @ApiPropertyOptional({ example: "https://storage.hotel.com/certs/cert-9981.pdf" })
  @IsOptional()
  @IsString()
  certificateUrl?: string;
}
