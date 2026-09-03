import { Module } from "@nestjs/common";
import { IncidentsController } from "./incidents.controller";
import { IncidentsService } from "./incidents.service";
import { IncidentsRepository } from "./incidents.repository";
import { NotificationsModule } from "../notifications/notifications.module";

@Module({
  imports: [NotificationsModule],
  controllers: [IncidentsController],
  providers: [IncidentsService, IncidentsRepository],
  exports: [IncidentsService, IncidentsRepository],
})
export class IncidentsModule {}
