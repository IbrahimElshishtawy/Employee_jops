import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsBoolean, IsNotEmpty, IsOptional, IsString } from "class-validator";

export class VerifyEmployeeDocumentDto {
  @ApiProperty({
    example: true,
    description: "Verification status",
  })
  @IsBoolean()
  @IsNotEmpty()
  isVerified: boolean;

  @ApiPropertyOptional({
    example: "Verified against original document",
    description: "Verification notes or remarks",
  })
  @IsString()
  @IsOptional()
  notes?: string;
}
