import { Module } from "@nestjs/common";
import { PayrollService } from "./payroll.service";
import { PayrollController } from "./payroll.controller";
import { PayrollCalculatorService } from "./payroll-calculator.service";

@Module({
  controllers: [PayrollController],
  providers: [PayrollService, PayrollCalculatorService],
  exports: [PayrollService, PayrollCalculatorService],
})
export class PayrollModule {}
