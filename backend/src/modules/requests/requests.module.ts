import { Module } from "@nestjs/common";
import { RequestsService } from "./requests.service";
import { RequestsController } from "./requests.controller";
import { RequestsRepository } from "./requests.repository";
import { WorkflowModule } from "../workflow/workflow.module";
import { ApprovalsModule } from "../approvals/approvals.module";
import { NotificationsModule } from "../notifications/notifications.module";

@Module({
  imports: [WorkflowModule, ApprovalsModule, NotificationsModule],
  controllers: [RequestsController],
  providers: [RequestsService, RequestsRepository],
  exports: [RequestsService, RequestsRepository],
})
export class RequestsModule {}
