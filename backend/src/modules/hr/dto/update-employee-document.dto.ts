import { ApiPropertyOptional, PartialType } from "@nestjs/swagger";
import { CreateEmployeeDocumentDto } from "./create-employee-document.dto";
import { IsBoolean, IsOptional } from "class-validator";

export class UpdateEmployeeDocumentDto extends PartialType(
  CreateEmployeeDocumentDto,
) {
  @ApiPropertyOptional({
    example: true,
    description: "Whether the document has been physically/digitally verified",
  })
  @IsBoolean()
  @IsOptional()
  isVerified?: boolean;
}
