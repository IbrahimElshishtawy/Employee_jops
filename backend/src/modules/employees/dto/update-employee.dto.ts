import { PartialType } from "@nestjs/swagger";
import { CreateEmployeeDto } from "./create-employee.dto";
import { IsEnum, IsOptional } from "class-validator";
import { UserStatus } from "@prisma/client";

export class UpdateEmployeeDto extends PartialType(CreateEmployeeDto) {
  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;
}
