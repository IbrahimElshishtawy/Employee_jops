import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNumber, IsOptional, IsString } from 'class-validator';
import { CheckInMethod } from '@prisma/client';

export class CheckInDto {
  @ApiProperty({ example: 24.7136, description: 'GPS Latitude' })
  @IsNumber()
  latitude: number;

  @ApiProperty({ example: 46.6753, description: 'GPS Longitude' })
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ enum: CheckInMethod, default: CheckInMethod.GPS })
  @IsOptional()
  @IsEnum(CheckInMethod)
  method?: CheckInMethod = CheckInMethod.GPS;

  @ApiPropertyOptional({ description: 'Connected Wi-Fi BSSID if applicable' })
  @IsOptional()
  @IsString()
  wifiBssid?: string;

  @ApiPropertyOptional({ description: 'Optional check-in notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}
