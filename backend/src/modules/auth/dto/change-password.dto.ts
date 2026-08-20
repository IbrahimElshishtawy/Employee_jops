import { ApiProperty } from "@nestjs/swagger";
import { IsNotEmpty, IsString, MinLength } from "class-validator";

export class ChangePasswordDto {
  @ApiProperty({ description: "Current password" })
  @IsString()
  @IsNotEmpty()
  oldPassword: string;

  @ApiProperty({ description: "New password (min 6 characters)" })
  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  newPassword: string;
}
