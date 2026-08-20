import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { AnnouncementStatus, AnnouncementTarget, NotificationPriority } from '@prisma/client';
import { PaginationQueryDto } from '../../../common/dto/pagination.dto';

export class CreateAnnouncementDto {
  @ApiProperty({
    example: 'Annual Company Gathering & Strategy Kickoff 2026',
    description: 'Title of the announcement',
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(200)
  title: string;

  @ApiProperty({
    example: 'We are excited to invite all team members to our annual celebration this Thursday...',
    description: 'Detailed content of the announcement',
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(10)
  body: string;

  @ApiPropertyOptional({
    enum: NotificationPriority,
    default: NotificationPriority.NORMAL,
    description: 'Priority level of announcement',
  })
  @IsOptional()
  @IsEnum(NotificationPriority)
  priority?: NotificationPriority = NotificationPriority.NORMAL;

  @ApiPropertyOptional({
    enum: AnnouncementTarget,
    default: AnnouncementTarget.ALL,
    description: 'Target audience scope for announcement',
  })
  @IsOptional()
  @IsEnum(AnnouncementTarget)
  targetType?: AnnouncementTarget = AnnouncementTarget.ALL;

  @ApiPropertyOptional({
    example: 'Engineering',
    description: 'Target department (required when targetType is DEPARTMENT)',
  })
  @IsOptional()
  @IsString()
  targetDepartment?: string;

  @ApiPropertyOptional({
    example: 'workplace-uuid-1',
    description: 'Target workplace ID (required when targetType is WORKPLACE)',
  })
  @IsOptional()
  @IsString()
  targetWorkplaceId?: string;

  @ApiPropertyOptional({
    example: ['emp-1', 'emp-2'],
    description: 'Target employee IDs (required when targetType is EMPLOYEES)',
  })
  @IsOptional()
  @IsArray()
  targetEmployeeIds?: string[];

  @ApiPropertyOptional({
    example: '2026-12-31T23:59:59Z',
    description: 'Optional expiration timestamp for announcement',
  })
  @IsOptional()
  @IsDateString()
  expiresAt?: string;

  @ApiPropertyOptional({
    default: false,
    description: 'If true, publishes announcement and broadcasts notifications immediately',
  })
  @IsOptional()
  publishNow?: boolean = false;
}

export class UpdateAnnouncementDto {
  @ApiPropertyOptional({ example: 'Updated Announcement Title' })
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  title?: string;

  @ApiPropertyOptional({ example: 'Updated Announcement Body' })
  @IsOptional()
  @IsString()
  @MinLength(10)
  body?: string;

  @ApiPropertyOptional({ enum: NotificationPriority })
  @IsOptional()
  @IsEnum(NotificationPriority)
  priority?: NotificationPriority;

  @ApiPropertyOptional({ enum: AnnouncementTarget })
  @IsOptional()
  @IsEnum(AnnouncementTarget)
  targetType?: AnnouncementTarget;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  targetDepartment?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  targetWorkplaceId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  targetEmployeeIds?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  expiresAt?: string;
}

export class QueryAnnouncementsDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    enum: AnnouncementStatus,
    description: 'Filter announcements by status (DRAFT, PUBLISHED, EXPIRED, CANCELLED)',
  })
  @IsOptional()
  @IsEnum(AnnouncementStatus)
  status?: AnnouncementStatus;

  @ApiPropertyOptional({
    enum: AnnouncementTarget,
    description: 'Filter by audience target type',
  })
  @IsOptional()
  @IsEnum(AnnouncementTarget)
  targetType?: AnnouncementTarget;

  @ApiPropertyOptional({
    example: 'Engineering',
    description: 'Filter by department',
  })
  @IsOptional()
  @IsString()
  department?: string;
}
