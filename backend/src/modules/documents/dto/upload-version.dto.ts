import { IsString, IsNotEmpty, IsOptional } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class UploadDocumentVersionDto {
  @ApiProperty({ example: "2.0", description: "New version string" })
  @IsString()
  @IsNotEmpty()
  versionNumber: string;

  @ApiProperty({ example: "https://storage.hotel.com/docs/sop-fd-checkin-v2.pdf" })
  @IsString()
  @IsNotEmpty()
  fileUrl: string;

  @ApiPropertyOptional({ example: "Updated with digital key card issuance steps" })
  @IsOptional()
  @IsString()
  changeSummary?: string;
}
