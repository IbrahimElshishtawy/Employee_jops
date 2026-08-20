import '../../../../core/rbac/app_permission.dart';
import '../../../../core/rbac/app_role.dart';

/// Authenticated HR User Entity
class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final AppRole role;
  final Set<AppPermission> customPermissions;
  final String? avatarUrl;
  final String? department;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.customPermissions = const {},
    this.avatarUrl,
    this.department,
  });
}
