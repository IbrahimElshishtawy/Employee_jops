import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from 'class-validator';
import { UserStatus } from '@prisma/client';

export class CreateSalaryProfileDto {
  @ApiProperty({
    example: 'emp-uuid-1234',
    description: 'Target Employee Profile UUID',
  })
  @IsString()
  @IsNotEmpty()
  employeeId: string;

  @ApiProperty({
    example: 15000,
    description: 'Basic monthly salary in specified currency',
  })
  @IsNumber()
  @Min(0)
  basicSalary: number;

  @ApiPropertyOptional({
    example: 2500,
    default: 0,
    description: 'Total monthly allowances (housing, transport, etc.)',
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  allowances?: number = 0;

  @ApiPropertyOptional({
    example: 'EGP',
    default: 'EGP',
    description: 'Salary currency code',
  })
  @IsOptional()
  @IsString()
  currency?: string = 'EGP';

  @ApiPropertyOptional({
    example: '2026-01-01',
    description: 'Date when this salary configuration becomes effective',
  })
  @IsOptional()
  @IsDateString()
  effectiveFrom?: string;

  @ApiProperty({
    example: 'Annual appraisal promotion / Initial hiring package',
    description: 'Reason or business rationale for setting this salary profile',
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  reason: string;
}

export class UpdateSalaryProfileDto {
  @ApiPropertyOptional({
    example: 18000,
    description: 'Updated basic monthly salary',
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  basicSalary?: number;

  @ApiPropertyOptional({
    example: 3000,
    description: 'Updated monthly allowances',
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  allowances?: number;

  @ApiPropertyOptional({
    example: 'EGP',
    description: 'Updated currency',
  })
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiPropertyOptional({
    example: '2026-09-01',
    description: 'Effective date for the updated salary',
  })
  @IsOptional()
  @IsDateString()
  effectiveDate?: string;

  @ApiPropertyOptional({
    enum: UserStatus,
    description: 'Status of salary profile',
  })
  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;

  @ApiProperty({
    example: 'Senior Engineer promotion & salary bump',
    description: 'Mandatory reason for modifying employee salary',
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  reason: string;
}
