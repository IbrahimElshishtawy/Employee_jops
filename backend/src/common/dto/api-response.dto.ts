import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ApiResponseDto<T> {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: 200 })
  statusCode: number;

  @ApiPropertyOptional({ example: 'Operation completed successfully' })
  message?: string;

  data: T;

  @ApiPropertyOptional({ example: { page: 1, limit: 10, total: 100, totalPages: 10 } })
  meta?: {
    page?: number;
    limit?: number;
    total?: number;
    totalPages?: number;
    hasNextPage?: boolean;
    hasPrevPage?: boolean;
  };

  @ApiProperty({ example: '2026-08-20T12:00:00.000Z' })
  timestamp: string;
}
