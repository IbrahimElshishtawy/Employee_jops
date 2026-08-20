import '../rbac/app_permission.dart';
import '../rbac/app_role.dart';
import '../rbac/authorization_service.dart';
import 'route_names.dart';

/// Route Authorization Guard evaluating RBAC before entering protected screens
class RouteGuards {
  RouteGuards._();

  static String? checkAuth({
    required bool isAuthenticated,
    required String currentPath,
  }) {
    final isGoingToLogin = currentPath == RouteNames.login;

    if (!isAuthenticated && !isGoingToLogin) {
      return RouteNames.login;
    }

    if (isAuthenticated && isGoingToLogin) {
      return RouteNames.dashboard;
    }

    return null;
  }

  static bool checkPermission({
    required AppRole role,
    required AppPermission requiredPermission,
  }) {
    return AuthorizationService.hasPermission(role, requiredPermission);
  }
}
