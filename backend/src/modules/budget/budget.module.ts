import { Module } from "@nestjs/common";
import { BudgetController } from "./budget.controller";
import { BudgetService } from "./budget.service";
import { BudgetRepository } from "./budget.repository";
import { NotificationsModule } from "../notifications/notifications.module";

@Module({
  imports: [NotificationsModule],
  controllers: [BudgetController],
  providers: [BudgetService, BudgetRepository],
  exports: [BudgetService, BudgetRepository],
})
export class BudgetModule {}
