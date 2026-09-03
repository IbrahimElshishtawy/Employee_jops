import { Module } from "@nestjs/common";
import { TrainingController } from "./training.controller";
import { TrainingService } from "./training.service";
import { TrainingRepository } from "./training.repository";
import { NotificationsModule } from "../notifications/notifications.module";

@Module({
  imports: [NotificationsModule],
  controllers: [TrainingController],
  providers: [TrainingService, TrainingRepository],
  exports: [TrainingService, TrainingRepository],
})
export class TrainingModule {}
