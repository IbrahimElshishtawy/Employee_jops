import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { Gender } from '@prisma/client';

export class CompleteProfileDto {
  @ApiProperty({ example: 'Tariq', description: 'Confirmed first name' })
  @IsString()
  @IsNotEmpty()
  firstName: string;

  @ApiProperty({ example: 'Zaid', description: 'Confirmed last name' })
  @IsString()
  @IsNotEmpty()
  lastName: string;

  @ApiProperty({ example: '1098765432', description: 'Official National ID / Resident ID' })
  @IsString()
  @IsNotEmpty()
  nationalId: string;

  @ApiProperty({ example: '+966500000003', description: 'Mobile phone number' })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiProperty({ example: 'Software Engineer', description: 'Official job title' })
  @IsString()
  @IsNotEmpty()
  jobTitle: string;

  @ApiProperty({ example: 'Engineering', description: 'Department / business unit' })
  @IsString()
  @IsNotEmpty()
  department: string;

  @ApiProperty({ example: 'uuid-workplace-id', description: 'Assigned workplace / office branch' })
  @IsString()
  @IsNotEmpty()
  workplaceId: string;

  @ApiPropertyOptional({ enum: Gender, example: Gender.MALE })
  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;
}
