import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsEnum, IsNotEmpty, IsOptional, IsString } from "class-validator";
import { DevicePlatform } from "@prisma/client";

export class RegisterDeviceTokenDto {
  @ApiProperty({
    description: "Firebase Cloud Messaging FCM Registration Token",
  })
  @IsString()
  @IsNotEmpty()
  fcmToken: string;

  @ApiPropertyOptional({
    enum: DevicePlatform,
    default: DevicePlatform.ANDROID,
  })
  @IsOptional()
  @IsEnum(DevicePlatform)
  platform?: DevicePlatform = DevicePlatform.ANDROID;

  @ApiPropertyOptional({ description: "Hardware or unique device UUID" })
  @IsOptional()
  @IsString()
  deviceId?: string;
}
