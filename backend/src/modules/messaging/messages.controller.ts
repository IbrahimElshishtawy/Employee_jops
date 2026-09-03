import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  BadRequestException,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiResponse,
} from "@nestjs/swagger";
import { MessagingService } from "./messaging.service";
import {
  CreateConversationDto,
  CreateGroupConversationDto,
  SendMessageDto,
  QueryMessagesDto,
} from "./dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { ConversationAccessGuard } from "./guards/conversation-access.guard";

@ApiTags("Internal Messaging & Conversations")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("messages")
export class MessagesController {
  constructor(private readonly messagingService: MessagingService) {}

  @Post("conversations")
  @ApiOperation({ summary: "Start a new 1-on-1 conversation" })
  @ApiResponse({
    status: 201,
    description: "Conversation started and initial message sent",
  })
  createConversation(
    @CurrentUser("id") senderId: string,
    @Body() dto: CreateConversationDto,
  ) {
    return this.messagingService.createConversation(senderId, dto);
  }

  @Post("groups")
  @ApiOperation({ summary: "Create a new group conversation with participants" })
  @ApiResponse({
    status: 201,
    description: "Group conversation created successfully",
  })
  createGroup(
    @CurrentUser("id") creatorId: string,
    @Body() dto: CreateGroupConversationDto,
  ) {
    return this.messagingService.createGroupConversation(creatorId, dto);
  }

  @Get("conversations")
  @ApiOperation({
    summary: "Get current user conversations list with unread badges",
  })
  getMyConversations(@CurrentUser("id") userId: string) {
    return this.messagingService.getUserConversations(userId);
  }

  @Get("unread-count")
  @ApiOperation({ summary: "Get total unread messages count for current user" })
  getUnreadMessageCount(@CurrentUser("id") userId: string) {
    return this.messagingService.getUnreadMessageCount(userId);
  }

  @Get("conversations/:id")
  @UseGuards(ConversationAccessGuard)
  @ApiOperation({ summary: "Get paginated message history for a conversation" })
  getMessages(
    @Param("id") conversationId: string,
    @CurrentUser("id") userId: string,
    @Query() query: QueryMessagesDto,
  ) {
    return this.messagingService.getConversationMessages(
      conversationId,
      userId,
      query,
    );
  }

  @Post("conversations/:id/messages")
  @UseGuards(ConversationAccessGuard)
  @ApiOperation({ summary: "Send a message in a conversation" })
  sendMessageInConv(
    @Param("id") conversationId: string,
    @CurrentUser("id") senderId: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.messagingService.sendMessage(conversationId, senderId, dto);
  }

  @Post()
  @ApiOperation({ summary: "Send a message (with conversationId in body)" })
  sendMessage(
    @CurrentUser("id") senderId: string,
    @Body() dto: SendMessageDto,
  ) {
    if (!dto.conversationId) {
      throw new BadRequestException("conversationId is required in body");
    }
    return this.messagingService.sendMessage(dto.conversationId, senderId, dto);
  }

  @Post("conversations/:id/read")
  @HttpCode(HttpStatus.OK)
  @UseGuards(ConversationAccessGuard)
  @ApiOperation({ summary: "Mark all messages in a conversation as read" })
  markConversationAsRead(
    @Param("id") conversationId: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.messagingService.markConversationAsRead(conversationId, userId);
  }

  @Delete(":id")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Soft delete a message (sender or HR admin)" })
  deleteMessage(
    @Param("id") messageId: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.messagingService.deleteMessage(messageId, userId);
  }
}
