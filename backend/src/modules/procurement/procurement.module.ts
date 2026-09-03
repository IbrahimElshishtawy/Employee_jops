import { Module } from "@nestjs/common";
import { ProcurementController } from "./procurement.controller";
import { ProcurementService } from "./procurement.service";
import { ProcurementRepository } from "./procurement.repository";
import { NotificationsModule } from "../notifications/notifications.module";

@Module({
  imports: [NotificationsModule],
  controllers: [ProcurementController],
  providers: [ProcurementService, ProcurementRepository],
  exports: [ProcurementService, ProcurementRepository],
})
export class ProcurementModule {}
