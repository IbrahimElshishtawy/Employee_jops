import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env_config.dart';
import '../core/network/api_client.dart';
import '../core/network/auth_interceptor.dart';
import '../core/security/session_manager.dart';
import '../core/security/token_storage.dart';
import '../core/storage/local_storage.dart';
import '../core/theme/theme_controller.dart';
import '../features/advances/domain/entities/advance_entity.dart';
import '../features/advances/data/repositories/api_advances_repository.dart';
import '../features/advances/data/repositories/mock_advances_repository.dart';
import '../features/attendance/domain/entities/attendance_record.dart';
import '../features/attendance/data/repositories/api_attendance_repository.dart';
import '../features/attendance/data/repositories/mock_attendance_repository.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/data/repositories/api_auth_repository.dart';
import '../features/authentication/data/repositories/mock_auth_repository.dart';
import '../features/authentication/presentation/controllers/auth_controller.dart';
import '../features/dashboard/domain/entities/dashboard_metrics.dart';
import '../features/dashboard/data/repositories/api_dashboard_repository.dart';
import '../features/dashboard/data/repositories/mock_dashboard_repository.dart';
import '../features/deductions/domain/entities/deduction_entity.dart';
import '../features/employees/domain/entities/employee_entity.dart';
import '../features/employees/data/repositories/api_employee_repository.dart';
import '../features/employees/data/repositories/mock_employee_repository.dart';
import '../features/requests/domain/entities/hr_request_entity.dart';
import '../features/requests/data/repositories/api_requests_repository.dart';
import '../features/requests/data/repositories/mock_requests_repository.dart';
import '../features/schedules/domain/entities/schedule_entity.dart';
import '../features/workplaces/domain/entities/workplace_entity.dart';
import '../features/workplaces/data/repositories/api_workplaces_repository.dart';
import '../features/workplaces/data/repositories/mock_workplaces_repository.dart';

/// Dependency Injection Container holding app services & repositories
class AppDependencies {
  final LocalStorage localStorage;
  final TokenStorage tokenStorage;
  final SessionManager sessionManager;
  final ThemeController themeController;
  final AuthRepository authRepository;
  final AuthController authController;
  final DashboardRepository dashboardRepository;
  final EmployeeRepository employeeRepository;
  final AttendanceRepository attendanceRepository;
  final RequestsRepository requestsRepository;
  final AdvancesRepository advancesRepository;
  final DeductionsRepository deductionsRepository;
  final WorkplacesRepository workplacesRepository;
  final SchedulesRepository schedulesRepository;

  AppDependencies({
    required this.localStorage,
    required this.tokenStorage,
    required this.sessionManager,
    required this.themeController,
    required this.authRepository,
    required this.authController,
    required this.dashboardRepository,
    required this.employeeRepository,
    required this.attendanceRepository,
    required this.requestsRepository,
    required this.advancesRepository,
    required this.deductionsRepository,
    required this.workplacesRepository,
    required this.schedulesRepository,
  });
}

/// Asynchronous bootstrap initialization
class AppBootstrap {
  static Future<AppDependencies> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorage(prefs);
    final tokenStorage = SharedPrefsTokenStorage(prefs);
    final sessionManager = SessionManager(tokenStorage);
    final themeController = ThemeController(localStorage);

    final httpClient = http.Client();
    final authInterceptor = AuthInterceptor(tokenStorage);
    final apiClient = HttpApiClient(httpClient, authInterceptor);

    final AuthRepository authRepository;
    final DashboardRepository dashboardRepository;
    final EmployeeRepository employeeRepository;
    final AttendanceRepository attendanceRepository;
    final RequestsRepository requestsRepository;
    final AdvancesRepository advancesRepository;
    final DeductionsRepository deductionsRepository;
    final WorkplacesRepository workplacesRepository;
    final SchedulesRepository schedulesRepository;

    if (EnvConfig.enableMockData) {
      authRepository = MockAuthRepository(tokenStorage);
      dashboardRepository = MockDashboardRepository();
      employeeRepository = MockEmployeeRepository();
      attendanceRepository = MockAttendanceRepository();
      requestsRepository = MockRequestsRepository();
      advancesRepository = MockAdvancesRepository();
      deductionsRepository = MockDeductionsRepository();
      workplacesRepository = MockWorkplacesRepository();
      schedulesRepository = MockSchedulesRepository();
    } else {
      authRepository = ApiAuthRepository(apiClient, tokenStorage);
      dashboardRepository = ApiDashboardRepository(apiClient);
      employeeRepository = ApiEmployeeRepository(apiClient);
      attendanceRepository = ApiAttendanceRepository(apiClient);
      requestsRepository = ApiRequestsRepository(apiClient);
      advancesRepository = ApiAdvancesRepository(apiClient);
      deductionsRepository = MockDeductionsRepository(); // Fallback for dev
      workplacesRepository = ApiWorkplacesRepository(apiClient);
      schedulesRepository = MockSchedulesRepository();
    }

    final authController = AuthController(authRepository, sessionManager);
    await authController.checkAuthStatus();

    return AppDependencies(
      localStorage: localStorage,
      tokenStorage: tokenStorage,
      sessionManager: sessionManager,
      themeController: themeController,
      authRepository: authRepository,
      authController: authController,
      dashboardRepository: dashboardRepository,
      employeeRepository: employeeRepository,
      attendanceRepository: attendanceRepository,
      requestsRepository: requestsRepository,
      advancesRepository: advancesRepository,
      deductionsRepository: deductionsRepository,
      workplacesRepository: workplacesRepository,
      schedulesRepository: schedulesRepository,
    );
  }
}
