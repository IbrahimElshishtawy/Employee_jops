import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/routing/route_guards.dart';
import 'package:hr_app/core/routing/route_names.dart';
import 'package:hr_app/core/utils/date_formatter.dart';
import 'package:hr_app/core/utils/validator.dart';

void main() {
  group('Route Guards Tests', () {
    test('Unauthenticated user attempting to access dashboard is redirected to /login', () {
      final redirect = RouteGuards.checkAuth(
        isAuthenticated: false,
        currentPath: RouteNames.dashboard,
      );
      expect(redirect, equals(RouteNames.login));
    });

    test('Authenticated user attempting to access /login is redirected to /dashboard', () {
      final redirect = RouteGuards.checkAuth(
        isAuthenticated: true,
        currentPath: RouteNames.login,
      );
      expect(redirect, equals(RouteNames.dashboard));
    });

    test('Authenticated user accessing protected route is allowed', () {
      final redirect = RouteGuards.checkAuth(
        isAuthenticated: true,
        currentPath: RouteNames.employees,
      );
      expect(redirect, isNull);
    });
  });

  group('Validators & Formatters Tests', () {
    test('Email validator correctly accepts valid and rejects invalid emails', () {
      expect(Validator.email('admin@cyberwise.test'), isNull);
      expect(Validator.email('invalid-email'), isNotNull);
      expect(Validator.email(''), isNotNull);
    });

    test('DateFormatter correctly formats dates', () {
      final testDate = DateTime(2026, 8, 20);
      expect(DateFormatter.toIsoDate(testDate), equals('2026-08-20'));
      expect(DateFormatter.toDisplayDate(testDate), equals('Aug 20, 2026'));
      expect(DateFormatter.toDisplayDate(null), equals('-'));
    });
  });
}
