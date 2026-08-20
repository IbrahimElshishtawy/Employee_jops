import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { PaginationQueryDto } from '../../../common/dto/pagination.dto';

export class CreateConversationDto {
  @ApiPropertyOptional({
    example: 'emp-uuid-123',
    description: 'Direct target user ID (HR representative or specific employee)',
  })
  @IsOptional()
  @IsString()
  participantUserId?: string;

  @ApiPropertyOptional({
    example: 'Salary inquiry & contract amendment question',
    description: 'Conversation title/topic',
  })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  title?: string;

  @ApiProperty({
    example: 'Hello HR Team, I have a question regarding my recent overtime calculation...',
    description: 'Initial message content to start the conversation',
  })
  @IsString()
  @IsNotEmpty({ message: 'Message content cannot be empty' })
  @MinLength(1)
  @MaxLength(3000)
  content: string;

  @ApiPropertyOptional({
    example: 'https://storage.cyberwise.internal/attachments/pay_stub_query.pdf',
    description: 'Optional file attachment URL',
  })
  @IsOptional()
  @IsString()
  attachmentUrl?: string;

  @ApiPropertyOptional({
    example: 'msg_idemp_key_123',
    description: 'Idempotency key to avoid duplicate message creation',
  })
  @IsOptional()
  @IsString()
  idempotencyKey?: string;
}

export class SendMessageDto {
  @ApiPropertyOptional({
    example: 'conv-uuid-123',
    description: 'Target conversation ID (if not provided in URL path)',
  })
  @IsOptional()
  @IsString()
  conversationId?: string;

  @ApiProperty({
    example: 'Thank you for following up. Here is the requested document.',
    description: 'Message text content (cannot be only whitespace)',
  })
  @IsString()
  @IsNotEmpty({ message: 'Message content cannot be empty' })
  @MinLength(1)
  @MaxLength(3000)
  content: string;

  @ApiPropertyOptional({
    example: 'https://storage.cyberwise.internal/attachments/doc.pdf',
    description: 'Optional attachment URL',
  })
  @IsOptional()
  @IsString()
  attachmentUrl?: string;

  @ApiPropertyOptional({
    example: 'msg_idemp_send_uuid_123',
    description: 'Idempotency key to prevent accidental duplicate submission',
  })
  @IsOptional()
  @IsString()
  idempotencyKey?: string;
}

export class QueryMessagesDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    description: 'Cursor timestamp or message ID for fetching older messages',
  })
  @IsOptional()
  @IsString()
  before?: string;
}
