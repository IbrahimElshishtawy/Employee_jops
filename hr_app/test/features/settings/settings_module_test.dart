import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/security/session_manager.dart';
import 'package:hr_app/core/security/token_storage.dart';
import 'package:hr_app/core/storage/local_storage.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/core/theme/theme_controller.dart';
import 'package:hr_app/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:hr_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hr_app/features/settings/data/repositories/mock_settings_repository.dart';
import 'package:hr_app/features/settings/domain/entities/settings_entity.dart';
import 'package:hr_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:hr_app/features/settings/presentation/pages/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Settings Controller Unit Tests', () {
    late MockSettingsRepository repository;
    late SettingsController controller;

    setUp(() async {
      repository = MockSettingsRepository();
      controller = SettingsController(repository, autoFetch: false);
      await controller.fetchSettings();
    });

    test('Initializes and loads default system configuration bundle', () {
      expect(controller.settings, isNotNull);
      expect(controller.settings!.company.companyName, equals('CyberWise IE'));
      expect(controller.settings!.attendance.defaultGracePeriodMinutes, equals(15));
      expect(controller.settings!.attendance.maxGpsAccuracyMeters, equals(50));
      expect(controller.settings!.security.sessionTimeoutMinutes, equals(60));
    });

    test('Updates company settings and notifies state', () async {
      final newComp = controller.settings!.company.copyWith(companyName: 'CyberWise Global IE');
      final ok = await controller.saveCompanySettings(newComp);

      expect(ok, isTrue);
      expect(controller.settings!.company.companyName, equals('CyberWise Global IE'));
      expect(controller.successMessage, contains('updated successfully'));
    });

    test('Updates attendance policy settings', () async {
      final newPolicy = controller.settings!.attendance.copyWith(defaultGracePeriodMinutes: 20);
      final ok = await controller.saveAttendancePolicy(newPolicy);

      expect(ok, isTrue);
      expect(controller.settings!.attendance.defaultGracePeriodMinutes, equals(20));
    });

    test('Updates security parameters', () async {
      final newSec = controller.settings!.security.copyWith(sessionTimeoutMinutes: 90);
      final ok = await controller.saveSecuritySettings(newSec);

      expect(ok, isTrue);
      expect(controller.settings!.security.sessionTimeoutMinutes, equals(90));
    });
  });

  group('Settings Module Widget Tests', () {
    late MockSettingsRepository repo;
    late AuthController authController;
    late ThemeController themeController;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorage(prefs);
      final tokenStorage = InMemoryTokenStorage();
      themeController = ThemeController(localStorage);
      repo = MockSettingsRepository();
      authController = AuthController(MockAuthRepository(tokenStorage), SessionManager(tokenStorage));
      await authController.login('admin@cyberwise.test', 'password123');
    });

    Widget createTestApp({required Widget child, bool isDark = false, bool autoFetch = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          ChangeNotifierProvider.value(value: themeController),
          Provider<SettingsRepository>.value(value: repo),
          ChangeNotifierProvider(create: (_) => SettingsController(repo, autoFetch: autoFetch)),
        ],
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets('SettingsScreen renders navigation subtabs, company form, and admin badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 850));
      await tester.pumpWidget(createTestApp(child: const SettingsScreen(), autoFetch: true, isDark: true));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('HR Portal Settings & System Policies'), findsOneWidget);
      expect(find.text('SETTINGS ADMIN'), findsOneWidget);
      expect(find.text('General & Company'), findsOneWidget);
      expect(find.text('Attendance Policy'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Security & Sessions'), findsOneWidget);
      expect(find.text('Company Name'), findsOneWidget);
      expect(find.text('Save Company Settings'), findsOneWidget);
    });

    testWidgets('SettingsScreen switches to Attendance Policy and displays grace period & GPS threshold', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 850));
      await tester.pumpWidget(createTestApp(child: const SettingsScreen(), autoFetch: true, isDark: false));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Attendance Policy'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Global Attendance Policy & Geofence Defaults'), findsOneWidget);
      expect(find.text('Default Grace Period (Minutes)'), findsOneWidget);
      expect(find.text('Max GPS Accuracy Threshold (Meters)'), findsOneWidget);
      expect(find.text('Save Attendance Policy'), findsOneWidget);
    });
  });
}
