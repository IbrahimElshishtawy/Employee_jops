import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_providers.dart';
import '../../features/advances/presentation/screens/advance_details_screen.dart';
import '../../features/advances/presentation/screens/advances_list_screen.dart';
import '../../features/advances/presentation/screens/expense_report_screen.dart';
import '../../features/advances/presentation/screens/new_advance_screen.dart';
import '../../features/attendance/presentation/screens/attendance_history_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/attendance/presentation/screens/attendance_verification_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/domain/models/app_notification.dart';
import '../../features/notifications/presentation/screens/notification_details_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/personal_info_screen.dart';
import '../../features/onboarding/presentation/screens/work_info_screen.dart';
import '../../features/onboarding/presentation/screens/review_screen.dart';
import '../../features/onboarding/presentation/screens/work_location_screen.dart';
import '../../features/onboarding/presentation/screens/biometric_setup_screen.dart';
import '../../features/permissions/presentation/screens/new_permission_screen.dart';
import '../../features/permissions/presentation/screens/permission_details_screen.dart';
import '../../features/permissions/presentation/screens/permissions_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/requests/presentation/screens/requests_hub_screen.dart';
import '../../features/settings/presentation/screens/developer_demo_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/vacations/presentation/screens/new_vacation_screen.dart';
import '../../features/vacations/presentation/screens/vacation_details_screen.dart';
import '../../features/vacations/presentation/screens/vacations_list_screen.dart';
import '../../features/communication/presentation/screens/communication_screen.dart';
import '../../features/communication/presentation/screens/department_employees_screen.dart';
import '../../features/communication/presentation/screens/employee_contact_screen.dart';
import '../../features/communication/presentation/screens/chat_screen.dart';
import '../../features/communication/presentation/screens/create_request_screen.dart';
import '../../features/communication/presentation/screens/request_details_screen.dart';
import '../../features/communication/presentation/screens/my_requests_screen.dart';
import '../../features/communication/presentation/screens/departments_screen.dart';
import '../../features/communication/presentation/screens/conversations_screen.dart';
import '../services/notification_router.dart';
import 'app_routes.dart';
import 'main_shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _requestsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'requests');
final _communicationNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'communication');
final _notificationsNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'notifications',
);
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

class _AuthRouterListenable extends ChangeNotifier {
  _AuthRouterListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  NotificationRouter.rootNavigatorKey = _rootNavigatorKey;
  final refreshListenable = _AuthRouterListenable(ref);
  ref.onDispose(() => refreshListenable.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;
      final isOnboarding = state.matchedLocation.startsWith('/onboarding');

      if (!authState.isInitialized) {
        return null;
      }

      if (!authState.isAuthenticated) {
        if (!isLogin && !isSplash) {
          return AppRoutes.login;
        }
        return null;
      }

      // User is authenticated
      final profileCompleted = authState.employee?.profileCompleted ?? false;

      // Incomplete profile: strictly confine to onboarding
      if (!profileCompleted) {
        if (!isOnboarding) {
          return AppRoutes.onboardingPersonal;
        }
        return null;
      }

      // Complete profile: redirect away from splash, login, or onboarding to home
      if (isLogin || isSplash || isOnboarding) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Splash & Login
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),

      // Onboarding Routes (full-screen, not in shell)
      GoRoute(
        path: AppRoutes.onboardingPersonal,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingWork,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WorkInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingReview,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingLocation,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WorkLocationScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingBiometric,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BiometricSetupScreen(),
      ),

      // Main Shell Route with Persistent Bottom Navigation
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // 1. Home Branch
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // 2. Requests Branch
          StatefulShellBranch(
            navigatorKey: _requestsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.requests,
                builder: (context, state) => const RequestsHubScreen(),
              ),
            ],
          ),

          // 3. Communication Branch
          StatefulShellBranch(
            navigatorKey: _communicationNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.communication,
                builder: (context, state) => const CommunicationScreen(),
              ),
            ],
          ),

          // 4. Notifications Branch
          StatefulShellBranch(
            navigatorKey: _notificationsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),

          // 5. Profile Branch
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Global Pushed Sub-routes
      GoRoute(
        path: AppRoutes.attendance,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.attendanceVerify,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final isCheckIn = state.uri.queryParameters['type'] != 'checkOut';
          return AttendanceVerificationScreen(isCheckIn: isCheckIn);
        },
      ),
      GoRoute(
        path: AppRoutes.attendanceHistory,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AttendanceHistoryScreen(),
      ),

      // Advances Sub-routes
      GoRoute(
        path: AppRoutes.advances,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdvancesListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const NewAdvanceScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return AdvanceDetailsScreen(advanceId: id);
            },
            routes: [
              GoRoute(
                path: 'report',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return ExpenseReportScreen(advanceId: id);
                },
              ),
            ],
          ),
        ],
      ),

      // Permissions Sub-routes
      GoRoute(
        path: AppRoutes.permissions,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PermissionsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const NewPermissionScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return PermissionDetailsScreen(permissionId: id);
            },
          ),
        ],
      ),

      // Vacations Sub-routes
      GoRoute(
        path: AppRoutes.vacations,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VacationsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const NewVacationScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return VacationDetailsScreen(vacationId: id);
            },
          ),
        ],
      ),

      // Notification Details
      GoRoute(
        path: AppRoutes.notificationDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final notif = state.extra as AppNotification?;
          return NotificationDetailsScreen(
            notificationId: id,
            notification: notif,
          );
        },
      ),

      // Settings & Demo
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'demo',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const DeveloperDemoScreen(),
          ),
        ],
      ),

      // Communication Sub-routes
      GoRoute(
        path: AppRoutes.departments,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DepartmentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.conversations,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.departmentEmployees,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final deptId = state.pathParameters['departmentId'] ?? '';
          return DepartmentEmployeesScreen(departmentId: deptId);
        },
      ),
      GoRoute(
        path: AppRoutes.employeeContact,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final empId = state.pathParameters['employeeId'] ?? '';
          return EmployeeContactScreen(employeeId: empId);
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final convId = state.pathParameters['conversationId'] ?? '';
          return ChatScreen(conversationId: convId);
        },
      ),
      GoRoute(
        path: AppRoutes.newDepartmentRequest,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final deptId = state.uri.queryParameters['deptId'];
          final recipientId = state.uri.queryParameters['recipientId'];
          return CreateRequestScreen(
            initialDepartmentId: deptId,
            initialRecipientId: recipientId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.departmentRequestDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['requestId'] ?? '';
          return RequestDetailsScreen(requestId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.myDepartmentRequests,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyRequestsScreen(),
      ),
    ],
  );
});
