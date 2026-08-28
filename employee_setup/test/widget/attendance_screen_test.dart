import 'package:employee_setup/app/app_providers.dart';
import 'package:employee_setup/core/localization/app_localizations.dart';
import 'package:employee_setup/core/mock/mock_database.dart';
import 'package:employee_setup/core/mock/models/app_session.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/core/theme/app_theme.dart';
import 'package:employee_setup/core/widgets/app_button.dart';
import 'package:employee_setup/features/attendance/data/services/mock_biometric_service.dart';
import 'package:employee_setup/features/attendance/data/services/mock_location_service.dart';
import 'package:employee_setup/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp({
  required Widget child,
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.light,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('AttendanceScreen Widget Tests', () {
    late SharedPrefsStorage storage;

    setUp(() async {
      storage = SharedPrefsStorage();
      await storage.init();
      await storage.clear();
    });

    testWidgets('AttendanceScreen renders all core sections', (tester) async {
      final locService = MockLocationService(
        mode: MockLocationMode.insideRange,
        customDistance: 2.3,
      );
      final bioService = MockBiometricService(
        mode: MockBiometricMode.alwaysSuccess,
      );

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            localStorageProvider.overrideWithValue(storage),
            mockLocationServiceProvider.overrideWithValue(locService),
            mockBiometricServiceProvider.overrideWithValue(bioService),
          ],
          child: const AttendanceScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Header and cards
      expect(find.text('الحضور والانصراف'), findsWidgets);
      expect(find.text('تسجيل الحضور'), findsWidgets);
      expect(find.text('حالة اليوم'), findsOneWidget);
      expect(find.text('جدول الدوام ومواعيد العمل'), findsOneWidget);
      expect(find.text('أكّد هويتك للمتابعة'), findsOneWidget);
      expect(find.text('الجدول الزمني لليوم'), findsOneWidget);
    });

    testWidgets('AttendanceScreen renders in Dark Theme without errors', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          themeMode: ThemeMode.dark,
          overrides: [
            localStorageProvider.overrideWithValue(storage),
          ],
          child: const AttendanceScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('الحضور والانصراف'), findsWidgets);
    });

    testWidgets('AttendanceScreen renders in English LTR without errors', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('en'),
          overrides: [
            localStorageProvider.overrideWithValue(storage),
          ],
          child: const AttendanceScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Attendance'), findsWidgets);
      expect(find.text('Check In'), findsWidgets);
      expect(find.text('Today\'s Status'), findsOneWidget);
    });

    testWidgets('Tapping Check In executes flow and updates to Checked In state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final locService = MockLocationService(
        mode: MockLocationMode.insideRange,
        customDistance: 2.3,
      );
      final bioService = MockBiometricService(
        mode: MockBiometricMode.alwaysSuccess,
      );

      final dbNotifier = MockDatabaseNotifier();
      // Start with clean slate and authenticated session
      dbNotifier.replaceState(
        MockDatabase.seed().copyWith(
          attendance: const [],
          session: () => AppSession.create(
            employeeId: 'EMP-1024',
            email: 'employee@company.com',
          ),
        ),
      );

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            localStorageProvider.overrideWithValue(storage),
            mockDatabaseProvider.overrideWith((ref) => dbNotifier),
            mockLocationServiceProvider.overrideWithValue(locService),
            mockBiometricServiceProvider.overrideWithValue(bioService),
          ],
          child: const AttendanceScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find primary Check In button in Action Section, ensure visible and tap it
      final checkInButton = find.widgetWithText(AppButton, 'تسجيل الحضور');
      expect(checkInButton, findsOneWidget);

      await tester.ensureVisible(checkInButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(checkInButton);
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Should now show Check Out available
      final checkOutButton = find.widgetWithText(AppButton, 'تسجيل الانصراف');
      expect(checkOutButton, findsOneWidget);
    });
  });
}
