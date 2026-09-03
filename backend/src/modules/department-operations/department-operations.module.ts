import { Module } from "@nestjs/common";
import { DepartmentOperationsController } from "./department-operations.controller";
import { DepartmentOperationsService } from "./department-operations.service";
import { DepartmentOperationsRepository } from "./department-operations.repository";
import { PrismaModule } from "../../prisma/prisma.module";
import { ServiceRequestsModule } from "../service-requests/service-requests.module";
import { DepartmentAccessGuard } from "./guards/department-access.guard";

@Module({
  imports: [PrismaModule, ServiceRequestsModule],
  controllers: [DepartmentOperationsController],
  providers: [
    DepartmentOperationsService,
    DepartmentOperationsRepository,
    DepartmentAccessGuard,
  ],
  exports: [DepartmentOperationsService, DepartmentOperationsRepository],
})
export class DepartmentOperationsModule {}
