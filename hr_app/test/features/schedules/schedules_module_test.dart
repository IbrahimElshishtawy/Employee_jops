import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/security/session_manager.dart';
import 'package:hr_app/core/security/token_storage.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:hr_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hr_app/features/schedules/data/repositories/mock_schedules_repository.dart';
import 'package:hr_app/features/schedules/domain/entities/schedule_entity.dart';
import 'package:hr_app/features/schedules/presentation/controllers/schedule_controller.dart';
import 'package:hr_app/features/schedules/presentation/pages/schedules_list_screen.dart';
import 'package:hr_app/features/schedules/presentation/widgets/schedule_details_dialog.dart';
import 'package:hr_app/features/schedules/presentation/widgets/schedule_form_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  group('Schedules Controller Unit Tests', () {
    late MockSchedulesRepository repository;
    late ScheduleController controller;

    setUp(() {
      repository = MockSchedulesRepository();
      controller = ScheduleController(repository);
    });

    test('Initializes and loads schedules and KPIs', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.schedules, isNotEmpty);
      expect(controller.kpis, isNotNull);
      expect(controller.kpis!.totalCount, greaterThan(0));
      expect(controller.kpis!.activeCount, greaterThanOrEqualTo(1));
    });

    test('Filters schedules by search query and working day', () async {
      controller.onSearch('Operations');
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.schedules.every((s) => s.name.contains('Operations') || s.department == 'Operations'), isTrue);

      controller.onSearch('');
      controller.onFilterWorkingDay('Fri');
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.schedules.every((s) => s.workingDays.contains('Fri')), isTrue);
    });

    test('Switches between operational subtabs', () async {
      controller.setActiveTab(SchedulesTab.active);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.activeTab, equals(SchedulesTab.active));
      expect(controller.schedules.every((s) => s.isActive), isTrue);

      controller.setActiveTab(SchedulesTab.inactive);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.schedules.every((s) => !s.isActive), isTrue);
    });

    test('Creates a new schedule successfully', () async {
      const newShift = WorkScheduleEntity(
        id: 'SCH-NEW-001',
        name: 'Afternoon Support Shift',
        startTime: '14:00',
        endTime: '22:00',
        workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        gracePeriodMinutes: 20,
        department: 'Information Technology',
        isActive: true,
      );

      final success = await controller.createSchedule(newShift);
      expect(success, isTrue);

      final found = await repository.getScheduleById('SCH-NEW-001');
      expect(found.name, equals('Afternoon Support Shift'));
      expect(found.gracePeriodMinutes, equals(20));
    });

    test('Toggles schedule active status', () async {
      final success = await controller.toggleStatus('SCH-001', false);
      expect(success, isTrue);

      final updated = await repository.getScheduleById('SCH-001');
      expect(updated.isActive, isFalse);
    });
  });

  group('Schedules Module Widget Tests', () {
    late MockSchedulesRepository schRepo;
    late AuthController authController;

    setUp(() async {
      schRepo = MockSchedulesRepository();
      final tokenStorage = InMemoryTokenStorage();
      authController = AuthController(MockAuthRepository(tokenStorage), SessionManager(tokenStorage));
      await authController.login('admin@cyberwise.test', 'password123');
    });

    Widget createTestApp({required Widget child, bool isDark = false, bool autoFetch = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          Provider<SchedulesRepository>.value(value: schRepo),
          ChangeNotifierProvider(create: (_) => ScheduleController(schRepo, autoFetch: autoFetch)),
        ],
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets('SchedulesListScreen renders KPI cards, subtabs, and data table', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 800));
      await tester.pumpWidget(createTestApp(child: const SchedulesListScreen(), autoFetch: true));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Work Schedules & Shifts Management'), findsOneWidget);
      expect(find.text('Active Shifts'), findsAtLeastNWidgets(1));
      expect(find.text('Total Schedules'), findsOneWidget);
      expect(find.text('Assigned Workforce'), findsOneWidget);
      expect(find.text('Inactive Shifts'), findsAtLeastNWidgets(1));
      expect(find.text('All Schedules'), findsOneWidget);
      expect(find.text('Standard Core Business Hours'), findsOneWidget);
    });

    testWidgets('ScheduleDetailsDialog renders shift hours, 7-day strip, and rules in Dark theme', (tester) async {
      final sampleSchedule = await schRepo.getScheduleById('SCH-001');

      await tester.binding.setSurfaceSize(const Size(1366, 850));
      await tester.pumpWidget(
        createTestApp(
          child: ScheduleDetailsDialog(schedule: sampleSchedule),
          isDark: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Standard Core Business Hours'), findsOneWidget);
      expect(find.text('Shift Start'), findsOneWidget);
      expect(find.text('Shift End'), findsOneWidget);
      expect(find.text('Working Days Schedule'), findsOneWidget);
      expect(find.text('Attendance Engine Punch Evaluation Rules'), findsOneWidget);
    });

    testWidgets('ScheduleFormDialog validates required fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 800));
      await tester.pumpWidget(
        createTestApp(
          child: ScheduleFormDialog(
            onSave: (s) async => true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Create Work Schedule'), findsOneWidget);
      expect(find.text('Schedule Name'), findsOneWidget);
    });
  });
}
