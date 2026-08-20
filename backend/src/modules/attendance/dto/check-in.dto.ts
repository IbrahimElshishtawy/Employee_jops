import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsBoolean,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
} from "class-validator";
import { CheckInMethod } from "@prisma/client";

export class CheckInDto {
  @ApiProperty({ example: 24.7136, description: "GPS Latitude" })
  @IsNumber()
  latitude: number;

  @ApiProperty({ example: 46.6753, description: "GPS Longitude" })
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({
    example: 12.5,
    description: "GPS horizontal accuracy in meters (readings > 50m rejected)",
  })
  @IsOptional()
  @IsNumber()
  accuracy?: number;

  @ApiPropertyOptional({
    description: "Unique client Request ID for replay protection & idempotency",
    example: "550e8400-e29b-41d4-a716-446655440000",
  })
  @IsOptional()
  @IsString()
  requestId?: string;

  @ApiPropertyOptional({ enum: CheckInMethod, default: CheckInMethod.GPS })
  @IsOptional()
  @IsEnum(CheckInMethod)
  method?: CheckInMethod = CheckInMethod.GPS;

  @ApiPropertyOptional({
    description: "True if local device biometric check passed",
  })
  @IsOptional()
  @IsBoolean()
  biometricVerified?: boolean;

  @ApiPropertyOptional({
    description: "True if mock location is detected on client",
  })
  @IsOptional()
  @IsBoolean()
  isMockLocation?: boolean;

  @ApiPropertyOptional({
    description: "True if VPN / Proxy is detected on client",
  })
  @IsOptional()
  @IsBoolean()
  isVpn?: boolean;

  @ApiPropertyOptional({ description: "True if jailbreak/root is detected" })
  @IsOptional()
  @IsBoolean()
  isJailbroken?: boolean;

  @ApiPropertyOptional({ description: "Connected Wi-Fi BSSID if applicable" })
  @IsOptional()
  @IsString()
  wifiBssid?: string;

  @ApiPropertyOptional({ description: "Optional check-in notes" })
  @IsOptional()
  @IsString()
  notes?: string;
}
