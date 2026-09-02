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
import { NotificationsModule } from "./modules/notifications/notifications.module";
import { MessagesModule } from "./modules/messages/messages.module";
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
    NotificationsModule,
    MessagesModule,
    ReportsModule,
    AuditLogsModule,
    TasksModule,
    WorkManagementModule,
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
