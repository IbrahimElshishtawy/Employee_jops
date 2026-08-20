import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/rbac/app_permission.dart';
import 'package:hr_app/core/rbac/app_role.dart';
import 'package:hr_app/core/rbac/authorization_service.dart';

void main() {
  group('RBAC AuthorizationService Tests', () {
    test('SUPER_ADMIN possesses all permissions unconditionally', () {
      for (final permission in AppPermission.values) {
        expect(
          AuthorizationService.hasPermission(AppRole.superAdmin, permission),
          isTrue,
          reason: 'SUPER_ADMIN should have ${permission.key}',
        );
      }
    });

    test('HR_ADMIN has employee CRUD permissions', () {
      expect(
        AuthorizationService.hasPermission(AppRole.hrAdmin, AppPermission.employeesCreate),
        isTrue,
      );
      expect(
        AuthorizationService.hasPermission(AppRole.hrAdmin, AppPermission.employeesDelete),
        isTrue,
      );
    });

    test('VIEWER has only read permissions and cannot create or approve', () {
      expect(
        AuthorizationService.hasPermission(AppRole.viewer, AppPermission.employeesRead),
        isTrue,
      );
      expect(
        AuthorizationService.hasPermission(AppRole.viewer, AppPermission.employeesCreate),
        isFalse,
      );
      expect(
        AuthorizationService.hasPermission(AppRole.viewer, AppPermission.requestsApprove),
        isFalse,
      );
      expect(
        AuthorizationService.hasPermission(AppRole.viewer, AppPermission.advancesApprove),
        isFalse,
      );
    });

    test('Role parsing from string key works properly with fallback', () {
      expect(AppRole.fromKey('SUPER_ADMIN'), equals(AppRole.superAdmin));
      expect(AppRole.fromKey('hr_manager'), equals(AppRole.hrManager));
      expect(AppRole.fromKey('INVALID_UNKNOWN_ROLE'), equals(AppRole.viewer));
      expect(AppRole.fromKey(null), equals(AppRole.viewer));
    });
  });
}
