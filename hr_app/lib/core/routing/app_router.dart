import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../../features/advances/presentation/pages/advances_list_screen.dart';
import '../../features/attendance/presentation/pages/attendance_list_screen.dart';
import '../../features/audit_logs/presentation/pages/audit_logs_screen.dart';
import '../../features/authentication/presentation/controllers/auth_controller.dart';
import '../../features/authentication/presentation/pages/login_screen.dart';
import '../../features/authentication/presentation/pages/not_found_screen.dart';
import '../../features/authentication/presentation/pages/unauthorized_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/deductions/presentation/pages/deductions_list_screen.dart';
import '../../features/employees/presentation/pages/employee_details_screen.dart';
import '../../features/employees/presentation/pages/employee_list_screen.dart';
import '../../features/messages/presentation/pages/messages_screen.dart';
import '../../features/notifications/presentation/pages/notifications_screen.dart';
import '../../features/reports/presentation/pages/reports_screen.dart';
import '../../features/requests/presentation/pages/requests_list_screen.dart';
import '../../features/schedules/presentation/pages/schedules_list_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/workplaces/presentation/pages/workplaces_list_screen.dart';
import '../rbac/app_permission.dart';
import '../rbac/authorization_service.dart';
import '../widgets/layout/hr_scaffold.dart';
import 'route_guards.dart';
import 'route_names.dart';

/// Central Declarative Router for CyberWise IE HR Portal
class AppRouter {
  static GoRouter createRouter(AuthController authController) {
    return GoRouter(
      initialLocation: RouteNames.dashboard,
      refreshListenable: authController,
      redirect: (context, state) {
        final isAuthenticated = authController.isAuthenticated;
        final currentPath = state.matchedLocation;
        return RouteGuards.checkAuth(
          isAuthenticated: isAuthenticated,
          currentPath: currentPath,
        );
      },
      errorBuilder: (context, state) => const NotFoundScreen(),
      routes: [
        // Public Auth Route
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),

        // System Pages
        GoRoute(
          path: RouteNames.unauthorized,
          builder: (context, state) => const UnauthorizedScreen(),
        ),
        GoRoute(
          path: RouteNames.notFound,
          builder: (context, state) => const NotFoundScreen(),
        ),

        // Authenticated Dashboard Shell
        ShellRoute(
          builder: (context, state, child) {
            final authCtrl = context.watch<AuthController>();
            final route = state.matchedLocation;
            final title = _getTitleForRoute(context, route);

            return HrScaffold(
              title: title,
              currentRoute: route,
              userRole: authCtrl.currentRole,
              userName: authCtrl.currentUser?.fullName ?? 'HR Staff',
              onLogout: () => authCtrl.logout(),
              body: child,
            );
          },
          routes: [
            GoRoute(
              path: RouteNames.dashboard,
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: RouteNames.employees,
              redirect: (context, state) => _guardPermission(authController, AppPermission.employeesRead),
              builder: (context, state) => const EmployeeListScreen(),
            ),
            GoRoute(
              path: RouteNames.employeeDetails,
              redirect: (context, state) => _guardPermission(authController, AppPermission.employeesRead),
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return EmployeeDetailsScreen(employeeId: id);
              },
            ),
            GoRoute(
              path: RouteNames.attendance,
              redirect: (context, state) => _guardPermission(authController, AppPermission.attendanceRead),
              builder: (context, state) => const AttendanceListScreen(),
            ),
            GoRoute(
              path: RouteNames.requests,
              redirect: (context, state) => _guardPermission(authController, AppPermission.requestsRead),
              builder: (context, state) => const RequestsListScreen(),
            ),
            GoRoute(
              path: RouteNames.advances,
              redirect: (context, state) => _guardPermission(authController, AppPermission.advancesRead),
              builder: (context, state) => const AdvancesListScreen(),
            ),
            GoRoute(
              path: RouteNames.deductions,
              redirect: (context, state) => _guardPermission(authController, AppPermission.deductionsRead),
              builder: (context, state) => const DeductionsListScreen(),
            ),
            GoRoute(
              path: RouteNames.workplaces,
              redirect: (context, state) => _guardPermission(authController, AppPermission.workplacesRead),
              builder: (context, state) => const WorkplacesListScreen(),
            ),
            GoRoute(
              path: RouteNames.schedules,
              redirect: (context, state) => _guardPermission(authController, AppPermission.schedulesRead),
              builder: (context, state) => const SchedulesListScreen(),
            ),
            GoRoute(
              path: RouteNames.reports,
              redirect: (context, state) => _guardPermission(authController, AppPermission.reportsRead),
              builder: (context, state) => const ReportsScreen(),
            ),
            GoRoute(
              path: RouteNames.notifications,
              builder: (context, state) => const NotificationsScreen(),
            ),
            GoRoute(
              path: RouteNames.messages,
              builder: (context, state) => const MessagesScreen(),
            ),
            GoRoute(
              path: RouteNames.auditLogs,
              redirect: (context, state) => _guardPermission(authController, AppPermission.auditLogsRead),
              builder: (context, state) => const AuditLogsScreen(),
            ),
            GoRoute(
              path: RouteNames.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );
  }

  static String? _guardPermission(AuthController authCtrl, AppPermission perm) {
    if (!AuthorizationService.hasPermission(authCtrl.currentRole, perm)) {
      return RouteNames.unauthorized;
    }
    return null;
  }

  static String _getTitleForRoute(BuildContext context, String route) {
    if (route.startsWith(RouteNames.dashboard)) return context.l10n.translate('nav_dashboard');
    if (route.startsWith(RouteNames.employees)) return context.l10n.translate('nav_employees');
    if (route.startsWith(RouteNames.attendance)) return context.l10n.translate('nav_attendance');
    if (route.startsWith(RouteNames.requests)) return context.l10n.translate('nav_requests');
    if (route.startsWith(RouteNames.advances)) return context.l10n.translate('nav_advances');
    if (route.startsWith(RouteNames.deductions)) return context.l10n.translate('nav_deductions');
    if (route.startsWith(RouteNames.workplaces)) return context.l10n.translate('nav_workplaces');
    if (route.startsWith(RouteNames.schedules)) return context.l10n.translate('nav_schedules');
    if (route.startsWith(RouteNames.reports)) return context.l10n.translate('nav_reports');
    if (route.startsWith(RouteNames.notifications)) return context.l10n.translate('nav_notifications');
    if (route.startsWith(RouteNames.messages)) return context.l10n.translate('nav_messages');
    if (route.startsWith(RouteNames.auditLogs)) return context.l10n.translate('nav_audit_logs');
    if (route.startsWith(RouteNames.settings)) return context.l10n.translate('nav_settings');
    return context.l10n.translate('app_title');
  }
}
