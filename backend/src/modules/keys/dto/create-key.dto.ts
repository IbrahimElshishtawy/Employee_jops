import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsInt,
  Min,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { KeyType, KeyStatus } from "@prisma/client";

export class CreateKeyDto {
  @ApiProperty({
    example: "KEY-RM-401",
    description: "Unique key identifier or RFID tag",
  })
  @IsString()
  @IsNotEmpty()
  keyCode: string;

  @ApiPropertyOptional({ enum: KeyType, default: KeyType.ROOM })
  @IsOptional()
  @IsEnum(KeyType)
  keyType?: KeyType;

  @ApiProperty({ example: "Master Key Suite 401" })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: "Front Desk Key Box 2, Slot 14" })
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional({ example: 2, default: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  totalCopies?: number;

  @ApiPropertyOptional({ enum: KeyStatus, default: KeyStatus.ACTIVE })
  @IsOptional()
  @IsEnum(KeyStatus)
  status?: KeyStatus;
}
