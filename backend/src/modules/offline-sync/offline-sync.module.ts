import { Module } from "@nestjs/common";
import { OfflineSyncController } from "./offline-sync.controller";
import { OfflineSyncService } from "./offline-sync.service";
import { OfflineSyncRepository } from "./offline-sync.repository";

@Module({
  controllers: [OfflineSyncController],
  providers: [OfflineSyncService, OfflineSyncRepository],
  exports: [OfflineSyncService, OfflineSyncRepository],
})
export class OfflineSyncModule {}
