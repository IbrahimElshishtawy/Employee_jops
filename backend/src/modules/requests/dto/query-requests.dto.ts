import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, IsDateString } from 'class-validator';
import { RequestStatus, RequestType } from '@prisma/client';
import { PaginationQueryDto } from '../../../common/dto/pagination.dto';

export class QueryRequestsDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    enum: RequestStatus,
    description: 'Filter by request status (PENDING, APPROVED, REJECTED, CANCELLED)',
  })
  @IsOptional()
  @IsEnum(RequestStatus)
  status?: RequestStatus;

  @ApiPropertyOptional({
    enum: RequestType,
    description: 'Filter by request type',
  })
  @IsOptional()
  @IsEnum(RequestType)
  type?: RequestType;

  @ApiPropertyOptional({
    description: 'Filter by specific Employee Profile ID (HR only)',
  })
  @IsOptional()
  @IsString()
  employeeId?: string;

  @ApiPropertyOptional({
    description: 'Filter by employee department (HR only)',
  })
  @IsOptional()
  @IsString()
  department?: string;

  @ApiPropertyOptional({
    description: 'Filter by workplace / branch ID (HR only)',
  })
  @IsOptional()
  @IsString()
  workplaceId?: string;

  @ApiPropertyOptional({
    example: '2026-09-01',
    description: 'Filter requests active on or after this date',
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    example: '2026-09-30',
    description: 'Filter requests active on or before this date',
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  @ApiPropertyOptional({
    enum: ['createdAt', 'startDate', 'status', 'type'],
    default: 'createdAt',
    description: 'Field to sort results by',
  })
  @IsOptional()
  @IsString()
  sortBy?: string = 'createdAt';

  @ApiPropertyOptional({
    enum: ['asc', 'desc'],
    default: 'desc',
    description: 'Sort order direction',
  })
  @IsOptional()
  @IsEnum(['asc', 'desc'])
  sortOrder?: 'asc' | 'desc' = 'desc';
}
