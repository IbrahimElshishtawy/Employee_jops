import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsArray,
  IsUrl,
} from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class CreateWebhookDto {
  @ApiProperty({ example: "Channel Manager Webhook" })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: "https://api.externalchannel.com/webhooks/hotel" })
  @IsUrl()
  @IsNotEmpty()
  targetUrl: string;

  @ApiProperty({
    example: ["room.status_changed", "guest.checked_in", "inventory.low_stock"],
  })
  @IsArray()
  @IsString({ each: true })
  events: string[];

  @ApiPropertyOptional({ example: 3, default: 3 })
  @IsOptional()
  retryLimit?: number;
}
