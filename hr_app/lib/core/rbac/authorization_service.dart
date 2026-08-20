import 'app_permission.dart';
import 'app_role.dart';

/// Central Authorization Engine for evaluating Role-Based Access Control (RBAC)
class AuthorizationService {
  AuthorizationService._();

  static final Map<AppRole, Set<AppPermission>> _defaultRolePermissions = {
    AppRole.superAdmin: AppPermission.values.toSet(),

    AppRole.hrAdmin: {
      AppPermission.employeesRead,
      AppPermission.employeesCreate,
      AppPermission.employeesUpdate,
      AppPermission.employeesDelete,
      AppPermission.attendanceRead,
      AppPermission.attendanceExport,
      AppPermission.requestsRead,
      AppPermission.requestsApprove,
      AppPermission.requestsReject,
      AppPermission.advancesRead,
      AppPermission.advancesApprove,
      AppPermission.deductionsRead,
      AppPermission.deductionsCreate,
      AppPermission.workplacesRead,
      AppPermission.workplacesCreate,
      AppPermission.workplacesUpdate,
      AppPermission.schedulesRead,
      AppPermission.schedulesCreate,
      AppPermission.schedulesUpdate,
      AppPermission.reportsRead,
      AppPermission.reportsExport,
      AppPermission.notificationsManage,
      AppPermission.messagesManage,
      AppPermission.auditLogsRead,
    },

    AppRole.hrManager: {
      AppPermission.employeesRead,
      AppPermission.employeesUpdate,
      AppPermission.attendanceRead,
      AppPermission.attendanceExport,
      AppPermission.requestsRead,
      AppPermission.requestsApprove,
      AppPermission.requestsReject,
      AppPermission.advancesRead,
      AppPermission.advancesApprove,
      AppPermission.deductionsRead,
      AppPermission.workplacesRead,
      AppPermission.schedulesRead,
      AppPermission.reportsRead,
      AppPermission.notificationsManage,
      AppPermission.messagesManage,
    },

    AppRole.hrEmployee: {
      AppPermission.employeesRead,
      AppPermission.attendanceRead,
      AppPermission.requestsRead,
      AppPermission.advancesRead,
      AppPermission.deductionsRead,
      AppPermission.workplacesRead,
      AppPermission.schedulesRead,
      AppPermission.reportsRead,
    },

    AppRole.viewer: {
      AppPermission.employeesRead,
      AppPermission.attendanceRead,
      AppPermission.requestsRead,
      AppPermission.advancesRead,
      AppPermission.deductionsRead,
      AppPermission.workplacesRead,
      AppPermission.schedulesRead,
      AppPermission.reportsRead,
      AppPermission.auditLogsRead,
    },
  };

  /// Returns true if the user's role has the requested permission
  static bool hasPermission(AppRole role, AppPermission permission, {Set<AppPermission>? customPermissions}) {
    if (role == AppRole.superAdmin) return true;
    if (customPermissions != null && customPermissions.contains(permission)) return true;
    final granted = _defaultRolePermissions[role] ?? {};
    return granted.contains(permission);
  }

  /// Returns true if the user possesses ANY of the listed permissions
  static bool hasAnyPermission(AppRole role, Iterable<AppPermission> permissions) {
    if (role == AppRole.superAdmin) return true;
    return permissions.any((p) => hasPermission(role, p));
  }

  /// Returns true if the user possesses ALL of the listed permissions
  static bool hasAllPermissions(AppRole role, Iterable<AppPermission> permissions) {
    if (role == AppRole.superAdmin) return true;
    return permissions.every((p) => hasPermission(role, p));
  }

  /// Get list of permissions granted to a role
  static Set<AppPermission> getPermissionsForRole(AppRole role) {
    return _defaultRolePermissions[role] ?? {};
  }
}
