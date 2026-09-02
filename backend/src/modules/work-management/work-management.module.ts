import { Module } from "@nestjs/common";
import { WorkManagementController } from "./work-management.controller";
import { WorkManagementService } from "./work-management.service";
import { WorkManagementRepository } from "./work-management.repository";
import { NotificationsModule } from "../notifications/notifications.module";

@Module({
  imports: [NotificationsModule],
  controllers: [WorkManagementController],
  providers: [WorkManagementService, WorkManagementRepository],
  exports: [WorkManagementService, WorkManagementRepository],
})
export class WorkManagementModule {}
