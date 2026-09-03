import { IsString, IsNotEmpty } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class EnrollEmployeeDto {
  @ApiProperty({ example: "emp-profile-uuid" })
  @IsString()
  @IsNotEmpty()
  employeeId: string;
}
