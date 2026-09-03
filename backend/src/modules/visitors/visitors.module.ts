import { Module } from "@nestjs/common";
import { VisitorsController } from "./visitors.controller";
import { VisitorsService } from "./visitors.service";
import { VisitorsRepository } from "./visitors.repository";
import { NotificationsModule } from "../notifications/notifications.module";

@Module({
  imports: [NotificationsModule],
  controllers: [VisitorsController],
  providers: [VisitorsService, VisitorsRepository],
  exports: [VisitorsService, VisitorsRepository],
})
export class VisitorsModule {}
