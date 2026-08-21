import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/security/session_manager.dart';
import 'package:hr_app/core/security/token_storage.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/features/advances/data/repositories/mock_advances_repository.dart';
import 'package:hr_app/features/advances/domain/entities/advance_entity.dart';
import 'package:hr_app/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:hr_app/features/attendance/domain/entities/attendance_record.dart';
import 'package:hr_app/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:hr_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hr_app/features/deductions/data/repositories/mock_deductions_repository.dart';
import 'package:hr_app/features/deductions/domain/entities/deduction_entity.dart';
import 'package:hr_app/features/employees/data/repositories/mock_employee_repository.dart';
import 'package:hr_app/features/employees/domain/entities/employee_entity.dart';
import 'package:hr_app/features/employees/presentation/controllers/employee_controller.dart';
import 'package:hr_app/features/employees/presentation/pages/employee_details_screen.dart';
import 'package:hr_app/features/employees/presentation/pages/employee_list_screen.dart';
import 'package:hr_app/features/employees/presentation/widgets/employee_assignment_dialog.dart';
import 'package:hr_app/features/employees/presentation/widgets/employee_form_dialog.dart';
import 'package:hr_app/features/employees/presentation/widgets/manual_attendance_dialog.dart';
import 'package:hr_app/features/requests/data/repositories/mock_requests_repository.dart';
import 'package:hr_app/features/requests/domain/entities/hr_request_entity.dart';
import 'package:hr_app/features/schedules/data/repositories/mock_schedules_repository.dart';
import 'package:hr_app/features/schedules/domain/entities/schedule_entity.dart';
import 'package:hr_app/features/workplaces/data/repositories/mock_workplaces_repository.dart';
import 'package:hr_app/features/workplaces/domain/entities/workplace_entity.dart';
import 'package:provider/provider.dart';

void main() {
  group('Employee Module Unit & Controller Tests', () {
    late MockEmployeeRepository repository;
    late EmployeeController controller;

    setUp(() {
      repository = MockEmployeeRepository();
      controller = EmployeeController(repository);
    });

    test('Loads initial employee list correctly', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.employees.isNotEmpty, isTrue);
      expect(controller.totalCount, equals(5));
    });

    test('Filters employees by search query', () async {
      controller.onSearch('Alex');
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.employees.length, equals(1));
      expect(controller.employees.first.fullName, contains('Alex'));
    });

    test('Filters employees by department', () async {
      controller.onFilterDepartment('Finance');
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.employees.every((e) => e.department == 'Finance'), isTrue);
    });

    test('Filters employees by status', () async {
      controller.onFilterStatus(EmployeeStatus.suspended);
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.employees.every((e) => e.status == EmployeeStatus.suspended), isTrue);
    });

    test('Creates a new employee', () async {
      final newEmp = EmployeeEntity(
        id: 'TEST-EMP-999',
        employeeCode: 'CW-999',
        fullName: 'Dr. Gordon Freeman (Test)',
        email: 'gordon.freeman@example.test',
        phone: '+201000000099',
        department: 'Engineering',
        jobTitle: 'Research Scientist',
        workplaceId: 'WP-001',
        workplaceName: 'HQ Main Tower',
        scheduleId: 'SCH-001',
        scheduleName: 'Standard Core',
        status: EmployeeStatus.active,
        joinedDate: DateTime.now(),
      );

      final success = await controller.createEmployee(newEmp);
      expect(success, isTrue);
      expect(controller.employees.any((e) => e.fullName.contains('Gordon Freeman')), isTrue);
    });

    test('Updates employee status and workplace/schedule assignment', () async {
      final successStatus = await controller.updateEmployeeStatus('TEST-EMP-001', EmployeeStatus.suspended);
      expect(successStatus, isTrue);

      final successAssign = await controller.assignWorkplaceAndSchedule(
        'TEST-EMP-001',
        workplaceId: 'WP-002',
        workplaceName: 'Tech Hub Branch',
        scheduleId: 'SCH-002',
        scheduleName: 'Morning Shift',
      );
      expect(successAssign, isTrue);

      final updated = await repository.getEmployeeById('TEST-EMP-001');
      expect(updated.status, equals(EmployeeStatus.suspended));
      expect(updated.workplaceId, equals('WP-002'));
      expect(updated.scheduleId, equals('SCH-002'));
    });
  });

  group('Employee Module Widget Tests', () {
    late MockEmployeeRepository empRepo;
    late MockWorkplacesRepository wpRepo;
    late MockSchedulesRepository schRepo;
    late MockAttendanceRepository attRepo;
    late MockRequestsRepository reqRepo;
    late MockAdvancesRepository advRepo;
    late MockDeductionsRepository dedRepo;
    late AuthController authController;

    setUp(() async {
      empRepo = MockEmployeeRepository();
      wpRepo = MockWorkplacesRepository();
      schRepo = MockSchedulesRepository();
      attRepo = MockAttendanceRepository();
      reqRepo = MockRequestsRepository();
      advRepo = MockAdvancesRepository();
      dedRepo = MockDeductionsRepository();
      final tokenStorage = InMemoryTokenStorage();
      authController = AuthController(MockAuthRepository(tokenStorage), SessionManager(tokenStorage));
      await authController.login('admin@cyberwise.test', 'password123');
    });

    Widget createTestApp({required Widget child, bool isDark = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          Provider<EmployeeRepository>.value(value: empRepo),
          Provider<WorkplacesRepository>.value(value: wpRepo),
          Provider<SchedulesRepository>.value(value: schRepo),
          Provider<AttendanceRepository>.value(value: attRepo),
          Provider<RequestsRepository>.value(value: reqRepo),
          Provider<AdvancesRepository>.value(value: advRepo),
          Provider<DeductionsRepository>.value(value: dedRepo),
          ChangeNotifierProvider(create: (_) => EmployeeController(empRepo)),
        ],
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('EmployeeListScreen renders header, search bar, and data table', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(createTestApp(child: const EmployeeListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Employees Directory'), findsOneWidget);
      expect(find.text('Add Employee'), findsOneWidget);
      expect(find.text('Alex Vance (Test)'), findsOneWidget);
      expect(find.text('Jordan Miller (Test)'), findsOneWidget);
    });

    testWidgets('EmployeeFormDialog renders input fields in Light and Dark mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        createTestApp(
          child: EmployeeFormDialog(
            onSave: (_) async => true,
          ),
          isDark: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Register New Employee'), findsOneWidget);
      expect(find.text('Full Legal Name'), findsOneWidget);
      expect(find.text('Email Address (Google Auth)'), findsOneWidget);
      expect(find.text('Create Employee'), findsOneWidget);
    });

    testWidgets('EmployeeAssignmentDialog renders workplace and schedule selectors', (tester) async {
      final sampleEmp = await tester.runAsync(() => empRepo.getEmployeeById('TEST-EMP-001'));
      expect(sampleEmp, isNotNull);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        createTestApp(
          child: EmployeeAssignmentDialog(
            employee: sampleEmp!,
            onSave: ({required scheduleId, required scheduleName, required workplaceId, required workplaceName}) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assign Workplace & Schedule'), findsOneWidget);
      expect(find.text('Authoritative Workplace'), findsOneWidget);
      expect(find.text('Assigned Shift Schedule'), findsOneWidget);
    });

    testWidgets('ManualAttendanceDialog renders punch adjustment form', (tester) async {
      final sampleEmp = await tester.runAsync(() => empRepo.getEmployeeById('TEST-EMP-001'));
      expect(sampleEmp, isNotNull);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        createTestApp(
          child: ManualAttendanceDialog(
            employee: sampleEmp!,
            onSave: ({required checkIn, required checkOut, required date, required reason, required status}) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manual Attendance Correction'), findsOneWidget);
      expect(find.text('Attendance Status'), findsOneWidget);
      expect(find.text('Mandatory Adjustment Reason'), findsOneWidget);
    });

    testWidgets('EmployeeDetailsScreen loads profile and displays tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        createTestApp(
          child: const EmployeeDetailsScreen(employeeId: 'TEST-EMP-001'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alex Vance (Test)'), findsWidgets);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('Salary & Compensation'), findsOneWidget);
      expect(find.text('Salary Advances'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Activity & Audit'), findsOneWidget);

      // Verify Overview info
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Employment Profile'), findsOneWidget);
      expect(find.text('Work Assignment & Geofencing'), findsOneWidget);

      // Switch to Attendance tab
      await tester.tap(find.text('Attendance'));
      await tester.pumpAndSettle();
      expect(find.text('Recorded Punches'), findsOneWidget);

      // Switch to Salary tab (User is SuperAdmin by default in MockAuth, so compensation metrics display)
      await tester.tap(find.text('Salary & Compensation'));
      await tester.pumpAndSettle();
      expect(find.text('Basic Monthly Salary'), findsOneWidget);
      expect(find.text('Estimated Net Pay'), findsOneWidget);
    });
  });
}
