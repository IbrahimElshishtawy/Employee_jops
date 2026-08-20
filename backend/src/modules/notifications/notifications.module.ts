import { Global, Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { AnnouncementsService } from './announcements.service';
import { AnnouncementsController } from './announcements.controller';

@Global()
@Module({
  controllers: [NotificationsController, AnnouncementsController],
  providers: [NotificationsService, AnnouncementsService],
  exports: [NotificationsService, AnnouncementsService],
})
export class NotificationsModule {}
