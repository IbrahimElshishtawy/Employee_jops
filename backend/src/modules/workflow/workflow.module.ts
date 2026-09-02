import { Module } from "@nestjs/common";
import { WorkflowService } from "./workflow.service";
import { WorkflowController } from "./workflow.controller";
import { WorkflowRepository } from "./workflow.repository";

@Module({
  controllers: [WorkflowController],
  providers: [WorkflowService, WorkflowRepository],
  exports: [WorkflowService, WorkflowRepository],
})
export class WorkflowModule {}
