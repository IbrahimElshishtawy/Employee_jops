import { Module } from "@nestjs/common";
import { MessagesController } from "./messages.controller";
import { MessagingService } from "./messaging.service";
import { MessagingRepository } from "./messaging.repository";
import { ConversationAccessGuard } from "./guards/conversation-access.guard";
import { PrismaModule } from "../../prisma/prisma.module";
import { NotificationsModule } from "../notifications/notifications.module";
import { RealTimeModule } from "../realtime/realtime.module";

@Module({
  imports: [PrismaModule, NotificationsModule, RealTimeModule],
  controllers: [MessagesController],
  providers: [MessagingService, MessagingRepository, ConversationAccessGuard],
  exports: [MessagingService, MessagingRepository],
})
export class MessagingModule {}
