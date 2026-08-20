import 'package:flutter/material.dart';
import 'app_permission.dart';
import 'app_role.dart';
import 'authorization_service.dart';

/// Widget-level permission guard.
/// Renders [child] if user has permission, otherwise renders [fallback] or SizedBox.shrink().
class PermissionGuard extends StatelessWidget {
  final AppRole userRole;
  final AppPermission permission;
  final Set<AppPermission>? customPermissions;
  final Widget child;
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    required this.userRole,
    required this.permission,
    this.customPermissions,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final isAuthorized = AuthorizationService.hasPermission(
      userRole,
      permission,
      customPermissions: customPermissions,
    );

    if (isAuthorized) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
