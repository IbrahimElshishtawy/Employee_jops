import { Module } from "@nestjs/common";
import { ServiceRequestsController } from "./service-requests.controller";
import { ServiceRequestsService } from "./service-requests.service";
import { ServiceRequestsRepository } from "./service-requests.repository";
import { PrismaModule } from "../../prisma/prisma.module";
import { NotificationsModule } from "../notifications/notifications.module";
import { WorkflowModule } from "../workflow/workflow.module";
import { ServiceRequestAccessGuard } from "./guards/service-request-access.guard";

@Module({
  imports: [PrismaModule, NotificationsModule, WorkflowModule],
  controllers: [ServiceRequestsController],
  providers: [
    ServiceRequestsService,
    ServiceRequestsRepository,
    ServiceRequestAccessGuard,
  ],
  exports: [ServiceRequestsService, ServiceRequestsRepository],
})
export class ServiceRequestsModule {}
