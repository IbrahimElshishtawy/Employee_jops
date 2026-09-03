import { IsString, IsNotEmpty, IsOptional } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class RegisterDeviceSessionDto {
  @ApiProperty({ example: "device-uuid-hardware" })
  @IsString()
  @IsNotEmpty()
  deviceId: string;

  @ApiPropertyOptional({ example: "iPhone 15 Pro" })
  @IsOptional()
  @IsString()
  deviceName?: string;

  @ApiPropertyOptional({ example: "MOBILE_IOS", default: "MOBILE_IOS" })
  @IsOptional()
  @IsString()
  deviceType?: string;

  @ApiPropertyOptional({ example: "iOS 17.5" })
  @IsOptional()
  @IsString()
  osVersion?: string;

  @ApiPropertyOptional({ example: "2.1.0" })
  @IsOptional()
  @IsString()
  appVersion?: string;

  @ApiPropertyOptional({ example: "192.168.1.100" })
  @IsOptional()
  @IsString()
  ipAddress?: string;

  @ApiPropertyOptional({ example: "fcm-device-token-string" })
  @IsOptional()
  @IsString()
  fcmToken?: string;
}
