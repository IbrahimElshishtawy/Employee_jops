import { IsString, IsNotEmpty, IsOptional } from "class-validator";

export class JoinConversationWsDto {
  @IsString()
  @IsNotEmpty()
  conversationId: string;
}

export class LeaveConversationWsDto {
  @IsString()
  @IsNotEmpty()
  conversationId: string;
}

export class SendMessageWsDto {
  @IsString()
  @IsNotEmpty()
  conversationId: string;

  @IsString()
  @IsNotEmpty()
  content: string;

  @IsOptional()
  @IsString()
  attachmentUrl?: string;

  @IsOptional()
  @IsString()
  idempotencyKey?: string;
}

export class TypingWsDto {
  @IsString()
  @IsNotEmpty()
  conversationId: string;
}

export class MarkReadWsDto {
  @IsString()
  @IsNotEmpty()
  conversationId: string;
}
