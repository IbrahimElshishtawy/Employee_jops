import { IsIn, IsNotEmpty, IsOptional, IsString } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class AcknowledgeHandoverDto {
  @ApiProperty({
    description: "Acknowledgement action",
    enum: ["ACKNOWLEDGE", "FLAG", "REJECT"],
    example: "ACKNOWLEDGE",
  })
  @IsIn(["ACKNOWLEDGE", "FLAG", "REJECT"])
  @IsNotEmpty()
  action: "ACKNOWLEDGE" | "FLAG" | "REJECT";

  @ApiPropertyOptional({
    description: "Confirmation notes from the incoming shift",
    example: "Shift received, all tools and open items verified on site.",
  })
  @IsOptional()
  @IsString()
  acknowledgementNotes?: string;

  @ApiPropertyOptional({
    description: "Discrepancies noted (e.g. missing tools, delayed items)",
    example: "Toolbox #3 key is missing from the designated cabinet.",
  })
  @IsOptional()
  @IsString()
  discrepancyNotes?: string;
}
