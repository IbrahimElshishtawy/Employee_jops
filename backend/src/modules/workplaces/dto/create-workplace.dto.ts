import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateWorkplaceDto {
  @ApiProperty({ example: 'Riyadh HQ' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'RYD-01' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiPropertyOptional({ example: 'King Fahd Road, Riyadh' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiProperty({ example: 24.7136 })
  @IsNumber()
  latitude: number;

  @ApiProperty({ example: 46.6753 })
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ example: 150.0, default: 100.0 })
  @IsOptional()
  @IsNumber()
  radiusMeters?: number;

  @ApiPropertyOptional({ example: 'aa:bb:cc:dd:ee:ff' })
  @IsOptional()
  @IsString()
  wifiBssid?: string;

  @ApiPropertyOptional({ example: '192.168.1.1' })
  @IsOptional()
  @IsString()
  wifiIp?: string;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
