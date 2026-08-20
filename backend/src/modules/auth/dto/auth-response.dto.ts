import { ApiProperty } from '@nestjs/swagger';
import { Role, UserStatus } from '@prisma/client';

export class UserProfileResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  email: string;

  @ApiProperty({ enum: Role })
  role: Role;

  @ApiProperty({ enum: UserStatus })
  status: UserStatus;

  @ApiProperty({ required: false })
  employeeProfileId?: string;

  @ApiProperty({ required: false })
  employeeCode?: string;

  @ApiProperty({ required: false })
  firstName?: string;

  @ApiProperty({ required: false })
  lastName?: string;

  @ApiProperty({ required: false })
  jobTitle?: string;

  @ApiProperty({ required: false })
  department?: string;

  @ApiProperty({ required: false })
  avatarUrl?: string;

  @ApiProperty({ required: false })
  workplaceId?: string;
}

export class AuthResponseDto {
  @ApiProperty({ description: 'Short-lived JWT Access Token' })
  accessToken: string;

  @ApiProperty({ description: 'Long-lived Refresh Token' })
  refreshToken: string;

  @ApiProperty({ description: 'Access token expiration in seconds', example: 900 })
  expiresIn: number;

  @ApiProperty({ type: UserProfileResponseDto })
  user: UserProfileResponseDto;
}
