import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { MessagesService } from "./messages.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("Messages")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("messages")
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Get("conversations")
  @ApiOperation({ summary: "Get current user conversations list" })
  getMyConversations(@CurrentUser("id") userId: string) {
    return this.messagesService.getUserConversations(userId);
  }

  @Get("conversations/:id")
  @ApiOperation({ summary: "Get messages for a conversation" })
  getMessages(@Param("id") conversationId: string, @Query("limit") limit = 50) {
    return this.messagesService.getMessages(conversationId, +limit);
  }

  @Post("conversations/:id")
  @ApiOperation({ summary: "Send a message in a conversation" })
  sendMessage(
    @Param("id") conversationId: string,
    @CurrentUser("id") senderId: string,
    @Body("content") content: string,
    @Body("attachmentUrl") attachmentUrl?: string,
  ) {
    return this.messagesService.sendMessage(
      conversationId,
      senderId,
      content,
      attachmentUrl,
    );
  }
}
