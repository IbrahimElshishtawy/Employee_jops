import { IsString, IsNotEmpty, IsOptional } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class AddInvestigationDto {
  @ApiProperty({
    example:
      "CCTV footage showed Housekeeping mopped floor at 11:25 with no wet floor cone placed.",
  })
  @IsString()
  @IsNotEmpty()
  findings: string;

  @ApiPropertyOptional({
    example: "Failure to follow SOP HK-042 (caution cone mandatory)",
  })
  @IsOptional()
  @IsString()
  rootCause?: string;

  @ApiPropertyOptional({
    example: "Refresher training on spill safety and equipment check",
  })
  @IsOptional()
  @IsString()
  recommendations?: string;
}
