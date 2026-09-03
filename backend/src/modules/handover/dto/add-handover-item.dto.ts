import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsBoolean,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { HandoverItemCategory, HandoverItemPriority } from "@prisma/client";

export class AddHandoverItemDto {
  @ApiProperty({
    description: "Item or issue title",
    example: "Late delivery of spare parts expected at 20:00",
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({
    description: "Detailed description",
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    enum: HandoverItemCategory,
    default: HandoverItemCategory.GENERAL,
  })
  @IsOptional()
  @IsEnum(HandoverItemCategory)
  category?: HandoverItemCategory;

  @ApiPropertyOptional({
    enum: HandoverItemPriority,
    default: HandoverItemPriority.MEDIUM,
  })
  @IsOptional()
  @IsEnum(HandoverItemPriority)
  priority?: HandoverItemPriority;

  @ApiPropertyOptional({
    description: "Linked open Task ID",
  })
  @IsOptional()
  @IsString()
  taskId?: string;

  @ApiPropertyOptional({
    description: "Linked Service Request ID",
  })
  @IsOptional()
  @IsString()
  serviceRequestId?: string;

  @ApiPropertyOptional({
    description: "Whether this item requires action from incoming shift",
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  requiresAction?: boolean;
}
