import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/security/session_manager.dart';
import 'package:hr_app/core/security/token_storage.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:hr_app/features/attendance/domain/entities/attendance_record.dart';
import 'package:hr_app/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:hr_app/features/attendance/presentation/pages/attendance_list_screen.dart';
import 'package:hr_app/features/attendance/presentation/widgets/attendance_details_dialog.dart';
import 'package:hr_app/features/attendance/presentation/widgets/attendance_event_timeline.dart';
import 'package:hr_app/features/attendance/presentation/widgets/offline_review_dialog.dart';
import 'package:hr_app/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:hr_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hr_app/features/employees/data/repositories/mock_employee_repository.dart';
import 'package:hr_app/features/employees/domain/entities/employee_entity.dart';
import 'package:hr_app/features/workplaces/data/repositories/mock_workplaces_repository.dart';
import 'package:hr_app/features/workplaces/domain/entities/workplace_entity.dart';
import 'package:provider/provider.dart';

void main() {
  group('Attendance Controller Unit Tests', () {
    late MockAttendanceRepository repository;
    late AttendanceController controller;

    setUp(() {
      repository = MockAttendanceRepository();
      controller = AttendanceController(repository);
    });

    test('Initializes and loads KPIs and default today records', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.records, isNotEmpty);
      expect(controller.kpis, isNotNull);
      expect(controller.kpis!.presentCount, greaterThanOrEqualTo(1));
    });

    test('Filters by DatePreset yesterday and this month', () async {
      controller.onSelectDatePreset(DatePreset.yesterday);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.datePreset, equals(DatePreset.yesterday));

      controller.onSelectDatePreset(DatePreset.thisMonth);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.datePreset, equals(DatePreset.thisMonth));
      expect(controller.records.length, greaterThanOrEqualTo(3));
    });

    test('Filters records by search query', () async {
      controller.onSelectDatePreset(DatePreset.thisMonth);
      await Future.delayed(const Duration(milliseconds: 200));

      controller.onSearch('Alex');
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.records.every((r) => r.employeeName.contains('Alex')), isTrue);
    });

    test('Switches to Suspicious tab and filters security flags', () async {
      controller.setActiveTab(AttendanceTab.suspicious);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.activeTab, equals(AttendanceTab.suspicious));
      expect(controller.records.every((r) => r.securityStatus == SecurityStatus.suspicious || r.isFlagged), isTrue);
    });

    test('Switches to Offline tab and reviews offline punch', () async {
      controller.setActiveTab(AttendanceTab.offline);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.records.every((r) => r.isOfflinePending), isTrue);

      final success = await controller.reviewOfflineRecord(
        'TEST-ATT-007',
        approve: true,
      );
      expect(success, isTrue);
    });

    test('Submits manual attendance correction', () async {
      final success = await controller.manualCorrection(
        employeeId: 'TEST-EMP-001',
        date: DateTime.now(),
        status: AttendanceStatus.present,
        checkInTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 9, 0),
        checkOutTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 17, 0),
        reason: 'Approved on-site field support',
      );
      expect(success, isTrue);
    });

    test('Exports attendance report', () async {
      final url = await controller.exportReport();
      expect(url, isNotNull);
      expect(url!.contains('.csv'), isTrue);
    });
  });

  group('Attendance Module Widget Tests', () {
    late MockAttendanceRepository attRepo;
    late MockWorkplacesRepository wpRepo;
    late MockEmployeeRepository empRepo;
    late AuthController authController;

    setUp(() async {
      attRepo = MockAttendanceRepository();
      wpRepo = MockWorkplacesRepository();
      empRepo = MockEmployeeRepository();
      final tokenStorage = InMemoryTokenStorage();
      authController = AuthController(MockAuthRepository(tokenStorage), SessionManager(tokenStorage));
      await authController.login('admin@cyberwise.test', 'password123');
    });

    Widget createTestApp({required Widget child, bool isDark = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          Provider<AttendanceRepository>.value(value: attRepo),
          Provider<WorkplacesRepository>.value(value: wpRepo),
          Provider<EmployeeRepository>.value(value: empRepo),
          ChangeNotifierProvider(create: (_) => AttendanceController(attRepo)),
        ],
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('AttendanceListScreen renders KPI cards, date presets, and data table', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 800));
      await tester.pumpWidget(createTestApp(child: const AttendanceListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Attendance Control Center'), findsOneWidget);
      expect(find.text('Present Today'), findsOneWidget);
      expect(find.text('Late Arrivals'), findsOneWidget);
      expect(find.text('Absences'), findsOneWidget);
      expect(find.text('Date Filter:'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('Export Report'), findsOneWidget);
    });

    testWidgets('AttendanceDetailsDialog renders telemetry, geofence, and event timeline', (tester) async {
      final sampleRecord = await attRepo.getAttendanceDetails('TEST-ATT-001');

      await tester.binding.setSurfaceSize(const Size(1366, 900));
      await tester.pumpWidget(
        createTestApp(
          child: AttendanceDetailsDialog(record: sampleRecord),
          isDark: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alex Vance (Test)'), findsOneWidget);
      expect(find.text('Check-In Telemetry'), findsOneWidget);
      expect(find.text('Check-Out Telemetry'), findsOneWidget);
      expect(find.text('INSIDE BOUNDARY'), findsOneWidget);
      expect(find.text('Shift Schedule & Rule Engine Decisions'), findsOneWidget);
      expect(find.text('Attendance Event Lifecycle & Audit Trail'), findsOneWidget);
    });

    testWidgets('OfflineReviewDialog renders offline review and rejection form', (tester) async {
      final sampleRecord = await attRepo.getAttendanceDetails('TEST-ATT-007');

      await tester.binding.setSurfaceSize(const Size(1366, 800));
      await tester.pumpWidget(
        createTestApp(
          child: OfflineReviewDialog(
            record: sampleRecord,
            onReview: ({required approve, reason}) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review Offline Attendance Punch'), findsOneWidget);
      expect(find.text('Approve Punch'), findsOneWidget);
      expect(find.text('Reject Punch'), findsOneWidget);

      // Tap Reject Punch to reveal mandatory justification input
      await tester.tap(find.text('Reject Punch'));
      await tester.pumpAndSettle();
      expect(find.text('Mandatory Rejection Justification Reason'), findsOneWidget);
      expect(find.text('Confirm Rejection'), findsOneWidget);
    });

    testWidgets('AttendanceEventTimeline renders vertical node steps in Light and Dark mode', (tester) async {
      final sampleEvents = [
        AttendanceEvent(
          id: '1',
          eventType: AttendanceEventType.checkInAttempted,
          timestamp: DateTime.now(),
          description: 'Check-in attempted from device',
        ),
        AttendanceEvent(
          id: '2',
          eventType: AttendanceEventType.geofenceValidated,
          timestamp: DateTime.now(),
          description: 'Geofence validated',
        ),
        AttendanceEvent(
          id: '3',
          eventType: AttendanceEventType.checkInAccepted,
          timestamp: DateTime.now(),
          description: 'Accepted',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AttendanceEventTimeline(events: sampleEvents),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check-in Attempted'), findsOneWidget);
      expect(find.text('Geofence Boundary Verified'), findsOneWidget);
      expect(find.text('Check-in Accepted'), findsOneWidget);
    });
  });
}
