import { Global, Module } from "@nestjs/common";
import { NotificationsService } from "./notifications.service";
import { NotificationsController } from "./notifications.controller";
import { NotificationsRepository } from "./notifications.repository";
import { FcmService } from "./fcm.service";
import { AnnouncementsService } from "./announcements.service";
import { AnnouncementsController } from "./announcements.controller";

@Global()
@Module({
  controllers: [NotificationsController, AnnouncementsController],
  providers: [
    NotificationsRepository,
    FcmService,
    NotificationsService,
    AnnouncementsService,
  ],
  exports: [
    NotificationsService,
    AnnouncementsService,
    FcmService,
    NotificationsRepository,
  ],
})
export class NotificationsModule {}
