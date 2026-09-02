import { Module } from "@nestjs/common";
import { TasksController } from "./tasks.controller";
import { TasksService } from "./tasks.service";
import { TasksRepository } from "./tasks.repository";
import { NotificationsModule } from "../notifications/notifications.module";
import { TaskAccessGuard } from "./guards/task-access.guard";

@Module({
  imports: [NotificationsModule],
  controllers: [TasksController],
  providers: [TasksService, TasksRepository, TaskAccessGuard],
  exports: [TasksService, TasksRepository],
})
export class TasksModule {}
