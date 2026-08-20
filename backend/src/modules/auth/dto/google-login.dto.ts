import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class GoogleLoginDto {
  @ApiProperty({
    description: 'Google ID Token / Credential string obtained from Google Sign-In on mobile/web',
    example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...google_id_token',
  })
  @IsString()
  @IsNotEmpty()
  idToken: string;

  @ApiPropertyOptional({
    description: 'Optional client device ID or installation UUID',
    example: 'c6b8f72a-9e12-4d15-8c01-fbb19d45e0aa',
  })
  @IsOptional()
  @IsString()
  deviceId?: string;
}
