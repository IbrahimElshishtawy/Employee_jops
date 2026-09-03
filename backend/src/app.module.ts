import { Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { ThrottlerModule, ThrottlerGuard } from "@nestjs/throttler";
import { APP_GUARD, APP_INTERCEPTOR, APP_FILTER } from "@nestjs/core";

import configuration from "./config/configuration";
import { validate } from "./config/env.validation";
import { PrismaModule } from "./prisma/prisma.module";
import { RedisModule } from "./common/redis/redis.module";
import { HealthModule } from "./modules/health/health.module";
import { AuthModule } from "./modules/auth/auth.module";
import { EmployeesModule } from "./modules/employees/employees.module";
import { WorkplacesModule } from "./modules/workplaces/workplaces.module";
import { AttendanceModule } from "./modules/attendance/attendance.module";
import { WorkforceModule } from "./modules/workforce/workforce.module";
import { SchedulesModule } from "./modules/schedules/schedules.module";
import { WorkflowModule } from "./modules/workflow/workflow.module";
import { ApprovalsModule } from "./modules/approvals/approvals.module";
import { RequestsModule } from "./modules/requests/requests.module";
import { PayrollModule } from "./modules/payroll/payroll.module";
import { RealTimeModule } from "./modules/realtime/realtime.module";
import { NotificationsModule } from "./modules/notifications/notifications.module";
import { MessagingModule } from "./modules/messaging/messaging.module";
import { ReportsModule } from "./modules/reports/reports.module";
import { AuditLogsModule } from "./modules/audit-logs/audit-logs.module";

import { OrganizationModule } from "./modules/organization/organization.module";
import { RolesModule } from "./modules/roles/roles.module";
import { PermissionsModule } from "./modules/permissions/permissions.module";
import { SettingsModule } from "./modules/settings/settings.module";
import { HrModule } from "./modules/hr/hr.module";
import { RecruitmentModule } from "./modules/recruitment/recruitment.module";
import { OnboardingModule } from "./modules/onboarding/onboarding.module";
import { TasksModule } from "./modules/tasks/tasks.module";
import { WorkManagementModule } from "./modules/work-management/work-management.module";
import { ServiceRequestsModule } from "./modules/service-requests/service-requests.module";
import { HandoverModule } from "./modules/handover/handover.module";
import { DepartmentOperationsModule } from "./modules/department-operations/department-operations.module";

import { AssetsModule } from "./modules/assets/assets.module";
import { MaintenanceModule } from "./modules/maintenance/maintenance.module";
import { KeysModule } from "./modules/keys/keys.module";
import { InventoryModule } from "./modules/inventory/inventory.module";
import { ProcurementModule } from "./modules/procurement/procurement.module";
import { FinanceModule } from "./modules/finance/finance.module";
import { BudgetModule } from "./modules/budget/budget.module";
import { IncidentsModule } from "./modules/incidents/incidents.module";
import { DocumentsModule } from "./modules/documents/documents.module";
import { LostFoundModule } from "./modules/lost-found/lost-found.module";
import { VisitorsModule } from "./modules/visitors/visitors.module";
import { PerformanceModule } from "./modules/performance/performance.module";
import { TrainingModule } from "./modules/training/training.module";
import { SessionsModule } from "./modules/sessions/sessions.module";
import { IntegrationsModule } from "./modules/integrations/integrations.module";
import { OfflineSyncModule } from "./modules/offline-sync/offline-sync.module";
import { DashboardModule } from "./modules/dashboard/dashboard.module";

import { AllExceptionsFilter } from "./common/filters/all-exceptions.filter";
import { TransformResponseInterceptor } from "./common/interceptors/transform-response.interceptor";
import { LoggingInterceptor } from "./common/interceptors/logging.interceptor";

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      validate,
    }),

    // Throttler / Rate Limiter
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        {
          ttl: config.get<number>("throttler.ttl") || 60,
          limit: config.get<number>("throttler.limit") || 100,
        },
      ],
    }),

    // Database & Cache
    PrismaModule,
    RedisModule,

    // Domain Modules
    HealthModule,
    AuthModule,
    OrganizationModule,
    RolesModule,
    PermissionsModule,
    SettingsModule,
    HrModule,
    RecruitmentModule,
    OnboardingModule,
    EmployeesModule,
    WorkplacesModule,
    AttendanceModule,
    WorkforceModule,
    SchedulesModule,
    WorkflowModule,
    ApprovalsModule,
    RequestsModule,
    PayrollModule,
    RealTimeModule,
    NotificationsModule,
    MessagingModule,
    ReportsModule,
    AuditLogsModule,
    TasksModule,
    WorkManagementModule,
    ServiceRequestsModule,
    HandoverModule,
    DepartmentOperationsModule,

    // Hotel ERP & Governance Modules
    AssetsModule,
    MaintenanceModule,
    KeysModule,
    InventoryModule,
    ProcurementModule,
    FinanceModule,
    BudgetModule,
    IncidentsModule,
    DocumentsModule,
    LostFoundModule,
    VisitorsModule,
    PerformanceModule,
    TrainingModule,
    SessionsModule,
    IntegrationsModule,
    OfflineSyncModule,
    DashboardModule,
  ],
  providers: [
    // Global Throttler Guard
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
    // Global Exception Filter
    {
      provide: APP_FILTER,
      useClass: AllExceptionsFilter,
    },
    // Global Response Transformer
    {
      provide: APP_INTERCEPTOR,
      useClass: TransformResponseInterceptor,
    },
    // Global Logging Interceptor
    {
      provide: APP_INTERCEPTOR,
      useClass: LoggingInterceptor,
    },
  ],
})
export class AppModule {}
