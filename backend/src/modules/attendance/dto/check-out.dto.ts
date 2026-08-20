import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';
import { CheckInMethod } from '@prisma/client';

export class CheckOutDto {
  @ApiProperty({ example: 24.7136, description: 'GPS Latitude' })
  @IsNumber()
  latitude: number;

  @ApiProperty({ example: 46.6753, description: 'GPS Longitude' })
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({
    example: 15.0,
    description: 'GPS horizontal accuracy in meters',
  })
  @IsOptional()
  @IsNumber()
  accuracy?: number;

  @ApiPropertyOptional({
    description: 'Unique client Request ID for replay protection & idempotency',
    example: '550e8400-e29b-41d4-a716-446655440001',
  })
  @IsOptional()
  @IsString()
  requestId?: string;

  @ApiPropertyOptional({ enum: CheckInMethod, default: CheckInMethod.GPS })
  @IsOptional()
  @IsEnum(CheckInMethod)
  method?: CheckInMethod = CheckInMethod.GPS;

  @ApiPropertyOptional({ description: 'True if local device biometric check passed' })
  @IsOptional()
  @IsBoolean()
  biometricVerified?: boolean;

  @ApiPropertyOptional({ description: 'True if mock location is detected' })
  @IsOptional()
  @IsBoolean()
  isMockLocation?: boolean;

  @ApiPropertyOptional({ description: 'True if VPN is detected' })
  @IsOptional()
  @IsBoolean()
  isVpn?: boolean;

  @ApiPropertyOptional({ description: 'True if device is rooted/jailbroken' })
  @IsOptional()
  @IsBoolean()
  isJailbroken?: boolean;

  @ApiPropertyOptional({ description: 'Optional check-out notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}
