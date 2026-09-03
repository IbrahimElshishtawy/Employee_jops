import { IsString, IsNotEmpty } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class ClaimLostFoundItemDto {
  @ApiProperty({ example: "Sarah Jenkins" })
  @IsString()
  @IsNotEmpty()
  claimantName: string;

  @ApiProperty({ example: "+15552345678" })
  @IsString()
  @IsNotEmpty()
  claimantPhone: string;

  @ApiProperty({ example: "US-P-98765432" })
  @IsString()
  @IsNotEmpty()
  claimantNationalId: string;
}
