import { Module } from "@nestjs/common";
import { PerformanceController } from "./performance.controller";
import { PerformanceService } from "./performance.service";
import { PerformanceRepository } from "./performance.repository";
import { NotificationsModule } from "../notifications/notifications.module";

@Module({
  imports: [NotificationsModule],
  controllers: [PerformanceController],
  providers: [PerformanceService, PerformanceRepository],
  exports: [PerformanceService, PerformanceRepository],
})
export class PerformanceModule {}
