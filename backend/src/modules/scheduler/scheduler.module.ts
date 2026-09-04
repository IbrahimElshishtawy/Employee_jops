import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { SchedulerService } from "./scheduler.service";
import { SchedulerController } from "./scheduler.controller";
import { DistributedLockService } from "./distributed-lock.service";
import { NotificationsModule } from "../notifications/notifications.module";
import { OfflineSyncModule } from "../offline-sync/offline-sync.module";

@Module({
  imports: [ConfigModule, NotificationsModule, OfflineSyncModule],
  controllers: [SchedulerController],
  providers: [SchedulerService, DistributedLockService],
  exports: [SchedulerService, DistributedLockService],
})
export class SchedulerModule {}
