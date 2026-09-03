import { Module } from "@nestjs/common";
import { HandoverController } from "./handover.controller";
import { HandoverService } from "./handover.service";
import { HandoverRepository } from "./handover.repository";
import { PrismaModule } from "../../prisma/prisma.module";
import { NotificationsModule } from "../notifications/notifications.module";
import { HandoverAccessGuard } from "./guards/handover-access.guard";

@Module({
  imports: [PrismaModule, NotificationsModule],
  controllers: [HandoverController],
  providers: [HandoverService, HandoverRepository, HandoverAccessGuard],
  exports: [HandoverService, HandoverRepository],
})
export class HandoverModule {}
