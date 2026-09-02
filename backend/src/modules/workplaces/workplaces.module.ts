import { Module } from "@nestjs/common";
import { WorkplacesService } from "./workplaces.service";
import { WorkplacesController } from "./workplaces.controller";
import { WorkplacesRepository } from "./workplaces.repository";

@Module({
  controllers: [WorkplacesController],
  providers: [WorkplacesService, WorkplacesRepository],
  exports: [WorkplacesService, WorkplacesRepository],
})
export class WorkplacesModule {}
