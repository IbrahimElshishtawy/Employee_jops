import { IsString, IsNotEmpty, IsOptional, IsEnum } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { DevicePlatform } from "@prisma/client";

export class RegisterDeviceSessionDto {
  @ApiProperty({ example: "session-token-string" })
  @IsString()
  @IsNotEmpty()
  sessionToken: string;

  @ApiPropertyOptional({
    enum: DevicePlatform,
    default: DevicePlatform.ANDROID,
  })
  @IsOptional()
  @IsEnum(DevicePlatform)
  devicePlatform?: DevicePlatform;

  @ApiPropertyOptional({ example: "iPhone 15 Pro" })
  @IsOptional()
  @IsString()
  deviceModel?: string;

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

  @ApiPropertyOptional({ example: "Mozilla/5.0 Mobile" })
  @IsOptional()
  @IsString()
  userAgent?: string;
}
