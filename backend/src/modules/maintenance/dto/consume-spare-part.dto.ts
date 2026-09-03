import { IsString, IsNotEmpty, IsInt, Min } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class ConsumeSparePartDto {
  @ApiProperty({ example: "spare-part-uuid" })
  @IsString()
  @IsNotEmpty()
  sparePartId: string;

  @ApiProperty({ example: 2, default: 1 })
  @IsInt()
  @Min(1)
  quantity: number;
}
