import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';
import { RequestType } from '@prisma/client';

export class CreateRequestDto {
  @ApiProperty({ enum: RequestType, example: RequestType.ANNUAL_LEAVE })
  @IsEnum(RequestType)
  @IsNotEmpty()
  type: RequestType;

  @ApiProperty({ example: '2026-09-01' })
  @IsDateString()
  @IsNotEmpty()
  startDate: string;

  @ApiProperty({ example: '2026-09-05' })
  @IsDateString()
  @IsNotEmpty()
  endDate: string;

  @ApiPropertyOptional({ example: '10:00' })
  @IsOptional()
  @IsString()
  startTime?: string;

  @ApiPropertyOptional({ example: '12:00' })
  @IsOptional()
  @IsString()
  endTime?: string;

  @ApiProperty({ example: 'Family emergency / vacation' })
  @IsString()
  @IsNotEmpty()
  reason: string;

  @ApiPropertyOptional({ example: 'https://storage.cyberwise.com/attachments/doc.pdf' })
  @IsOptional()
  @IsString()
  attachmentUrl?: string;
}
