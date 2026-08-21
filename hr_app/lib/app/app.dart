import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config/app_config.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/advances/domain/entities/advance_entity.dart';
import '../features/advances/presentation/controllers/advances_controller.dart';
import '../features/attendance/domain/entities/attendance_record.dart';
import '../features/attendance/presentation/controllers/attendance_controller.dart';
import '../features/dashboard/domain/entities/dashboard_metrics.dart';
import '../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../features/deductions/domain/entities/deduction_entity.dart';
import '../features/deductions/presentation/controllers/deductions_controller.dart';
import '../features/employees/domain/entities/employee_entity.dart';
import '../features/employees/presentation/controllers/employee_controller.dart';
import '../features/reports/domain/entities/report_entities.dart';
import '../features/reports/presentation/controllers/reports_controller.dart';
import '../features/requests/domain/entities/hr_request_entity.dart';
import '../features/requests/presentation/controllers/requests_controller.dart';
import '../features/schedules/domain/entities/schedule_entity.dart';
import '../features/schedules/presentation/controllers/schedule_controller.dart';
import '../features/workplaces/domain/entities/workplace_entity.dart';
import '../features/workplaces/presentation/controllers/workplace_controller.dart';
import 'app_bootstrap.dart';

/// Root HR Portal Application Widget
class HrApp extends StatelessWidget {
  final AppDependencies dependencies;

  const HrApp({super.key, required this.dependencies});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.createRouter(dependencies.authController);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dependencies.themeController),
        ChangeNotifierProvider.value(value: dependencies.authController),
        Provider<DashboardRepository>.value(value: dependencies.dashboardRepository),
        Provider<EmployeeRepository>.value(value: dependencies.employeeRepository),
        Provider<AttendanceRepository>.value(value: dependencies.attendanceRepository),
        Provider<RequestsRepository>.value(value: dependencies.requestsRepository),
        Provider<AdvancesRepository>.value(value: dependencies.advancesRepository),
        Provider<DeductionsRepository>.value(value: dependencies.deductionsRepository),
        Provider<WorkplacesRepository>.value(value: dependencies.workplacesRepository),
        Provider<SchedulesRepository>.value(value: dependencies.schedulesRepository),
        Provider<ReportsRepository>.value(value: dependencies.reportsRepository),
        ChangeNotifierProvider(
          create: (_) => DashboardController(dependencies.dashboardRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => EmployeeController(dependencies.employeeRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceController(dependencies.attendanceRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => RequestsController(dependencies.requestsRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AdvancesController(dependencies.advancesRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => DeductionsController(dependencies.deductionsRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleController(dependencies.schedulesRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => WorkplaceController(
            dependencies.workplacesRepository,
            dependencies.employeeRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportsController(dependencies.reportsRepository),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) {
          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeCtrl.themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
