import { Module } from "@nestjs/common";
import { MaintenanceController } from "./maintenance.controller";
import { MaintenanceService } from "./maintenance.service";
import { MaintenanceRepository } from "./maintenance.repository";
import { NotificationsModule } from "../notifications/notifications.module";

@Module({
  imports: [NotificationsModule],
  controllers: [MaintenanceController],
  providers: [MaintenanceService, MaintenanceRepository],
  exports: [MaintenanceService, MaintenanceRepository],
})
export class MaintenanceModule {}
