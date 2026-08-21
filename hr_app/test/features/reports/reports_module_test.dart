import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/security/session_manager.dart';
import 'package:hr_app/core/security/token_storage.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:hr_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hr_app/features/reports/data/repositories/mock_reports_repository.dart';
import 'package:hr_app/features/reports/domain/entities/report_entities.dart';
import 'package:hr_app/features/reports/presentation/controllers/reports_controller.dart';
import 'package:hr_app/features/reports/presentation/pages/reports_screen.dart';
import 'package:hr_app/features/reports/presentation/widgets/report_export_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  group('Reports Controller Unit Tests', () {
    late MockReportsRepository repository;
    late ReportsController controller;

    setUp(() {
      repository = MockReportsRepository();
      controller = ReportsController(repository);
    });

    test('Initializes and loads overview KPIs and analytics', () async {
      await Future.delayed(const Duration(milliseconds: 350));
      expect(controller.overview, isNotNull);
      expect(controller.overview!.totalEmployees, equals(48));
      expect(controller.overview!.presentCount, equals(44));
      expect(controller.overview!.attendanceRate, greaterThan(90));
      expect(controller.trends, isNotEmpty);
      expect(controller.departments, isNotEmpty);
      expect(controller.lateArrivals, isNotEmpty);
    });

    test('Updates filter with date presets and department', () async {
      controller.setDatePreset(DateRangePreset.thisWeek);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.filter.datePreset, equals(DateRangePreset.thisWeek));

      controller.setDepartment('Engineering');
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.filter.department, equals('Engineering'));
    });

    test('Switches between report subtabs', () {
      controller.setActiveTab(ReportsTab.lateArrivals);
      expect(controller.activeTab, equals(ReportsTab.lateArrivals));

      controller.setActiveTab(ReportsTab.financials);
      expect(controller.activeTab, equals(ReportsTab.financials));
    });

    test('Triggers export report and returns download url', () async {
      final url = await controller.exportReport('attendance', 'CSV');
      expect(url.toLowerCase(), contains('.csv'));
    });
  });

  group('Reports Module Widget Tests', () {
    late MockReportsRepository repo;
    late AuthController authController;

    setUp(() async {
      repo = MockReportsRepository();
      final tokenStorage = InMemoryTokenStorage();
      authController = AuthController(MockAuthRepository(tokenStorage), SessionManager(tokenStorage));
      await authController.login('admin@cyberwise.test', 'password123');
    });

    Widget createTestApp({required Widget child, bool isDark = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          Provider<ReportsRepository>.value(value: repo),
          ChangeNotifierProvider(create: (_) => ReportsController(repo)),
        ],
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets('ReportsScreen renders overview KPIs and progress meter', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      await tester.pumpWidget(createTestApp(child: const ReportsScreen()));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Executive Reports & Workforce Analytics'), findsOneWidget);
      expect(find.text('Attendance Rate'), findsOneWidget);
      expect(find.text('Punctuality Rate'), findsOneWidget);
      expect(find.text('Late Arrivals'), findsOneWidget);
      expect(find.text('Absences'), findsOneWidget);
      expect(find.text('Pending Requests'), findsOneWidget);
      expect(find.text('Salary Advances'), findsOneWidget);
      expect(find.text('Total Deductions'), findsOneWidget);
    });

    testWidgets('ReportExportDialog renders formats and handles download in Dark theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 800));
      await tester.pumpWidget(
        createTestApp(
          child: ReportExportDialog(
            reportTitle: 'Attendance Analytics',
            reportType: 'attendance',
            activeFilter: const ReportFilter(),
            onExport: (type, filter, format) async => 'https://cyberwise.test/export.csv',
          ),
          isDark: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Export Attendance Analytics'), findsOneWidget);
      expect(find.text('Comma Separated Values (.csv)'), findsOneWidget);
      expect(find.text('Generate & Download'), findsOneWidget);

      await tester.tap(find.text('Generate & Download'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Report Generated Successfully!'), findsOneWidget);
    });
  });
}
