import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({ example: 'admin@cyberwise.com', description: 'User corporate email' })
  @IsEmail({}, { message: 'Please provide a valid corporate email' })
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'Admin@123456', description: 'User password' })
  @IsString()
  @IsNotEmpty()
  @MinLength(6, { message: 'Password must be at least 6 characters long' })
  password: string;
}
