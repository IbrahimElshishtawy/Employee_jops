import { Module } from "@nestjs/common";
import { WorkforceController } from "./workforce.controller";
import { WorkforceService } from "./workforce.service";
import { WorkforceRepository } from "./workforce.repository";

@Module({
  controllers: [WorkforceController],
  providers: [WorkforceService, WorkforceRepository],
  exports: [WorkforceService, WorkforceRepository],
})
export class WorkforceModule {}
