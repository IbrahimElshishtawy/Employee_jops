import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { Gender, Role } from '@prisma/client';

export class CreateEmployeeDto {
  @ApiProperty({ example: 'employee@cyberwise.com' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'Emp@123456' })
  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  password: string;

  @ApiProperty({ example: 'CW-1001' })
  @IsString()
  @IsNotEmpty()
  employeeCode: string;

  @ApiProperty({ example: 'Omar' })
  @IsString()
  @IsNotEmpty()
  firstName: string;

  @ApiProperty({ example: 'Khalid' })
  @IsString()
  @IsNotEmpty()
  lastName: string;

  @ApiPropertyOptional({ example: '+966501112233' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: '1098765432' })
  @IsOptional()
  @IsString()
  nationalId?: string;

  @ApiProperty({ example: 'Software Engineer' })
  @IsString()
  @IsNotEmpty()
  jobTitle: string;

  @ApiProperty({ example: 'Engineering' })
  @IsString()
  @IsNotEmpty()
  department: string;

  @ApiPropertyOptional({ enum: Gender })
  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @ApiPropertyOptional({ enum: Role, default: Role.EMPLOYEE })
  @IsOptional()
  @IsEnum(Role)
  role?: Role = Role.EMPLOYEE;

  @ApiPropertyOptional({ example: 'uuid-workplace-id' })
  @IsOptional()
  @IsString()
  workplaceId?: string;

  @ApiPropertyOptional({ example: 'uuid-schedule-id' })
  @IsOptional()
  @IsString()
  scheduleId?: string;

  @ApiPropertyOptional({ example: 'uuid-manager-profile-id' })
  @IsOptional()
  @IsString()
  managerId?: string;

  @ApiPropertyOptional({ example: 8500.0 })
  @IsOptional()
  @IsNumber()
  baseSalary?: number;
}
