import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/security/session_manager.dart';
import 'package:hr_app/core/security/token_storage.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:hr_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hr_app/features/deductions/data/repositories/mock_deductions_repository.dart';
import 'package:hr_app/features/deductions/domain/entities/deduction_entity.dart';
import 'package:hr_app/features/deductions/presentation/controllers/deductions_controller.dart';
import 'package:hr_app/features/deductions/presentation/pages/deductions_list_screen.dart';
import 'package:hr_app/features/deductions/presentation/widgets/deduction_details_dialog.dart';
import 'package:hr_app/features/deductions/presentation/widgets/deduction_form_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  group('Deductions Controller Unit Tests', () {
    late MockDeductionsRepository repository;
    late DeductionsController controller;

    setUp(() {
      repository = MockDeductionsRepository();
      controller = DeductionsController(repository);
    });

    test('Initializes and loads deductions and financial KPIs', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.deductions, isNotEmpty);
      expect(controller.kpis, isNotNull);
      expect(controller.kpis!.totalAmount, greaterThan(0));
    });

    test('Filters deductions by search query and type', () async {
      controller.onSearch('Alex');
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.deductions.every((d) => d.employeeName.contains('Alex')), isTrue);

      controller.onSearch('');
      controller.onFilterType(DeductionType.absence);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.deductions.every((d) => d.type == DeductionType.absence), isTrue);
    });

    test('Switches between operational subtabs', () async {
      controller.setActiveTab(DeductionsTab.scheduled);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.activeTab, equals(DeductionsTab.scheduled));
      expect(controller.deductions.every((d) => d.status == DeductionStatus.scheduled), isTrue);

      controller.setActiveTab(DeductionsTab.applied);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.deductions.every((d) => d.status == DeductionStatus.applied), isTrue);
    });

    test('Creates a manual deduction successfully', () async {
      final newDed = DeductionEntity(
        id: 'TEST-DED-NEW',
        employeeId: 'TEST-EMP-001',
        employeeName: 'Alex Vance (Test)',
        employeeCode: 'CW-001',
        type: DeductionType.damage,
        amount: 80.00,
        currency: 'USD',
        status: DeductionStatus.scheduled,
        payrollPeriod: 'August 2026 Payroll',
        reason: 'Office equipment damage recovery',
        date: DateTime.now(),
        createdBy: 'HR Admin (Test)',
      );

      final success = await controller.createDeduction(newDed);
      expect(success, isTrue);

      final found = await repository.getDeductionById('TEST-DED-NEW');
      expect(found.amount, equals(80.00));
      expect(found.type, equals(DeductionType.damage));
    });

    test('Cancels a scheduled deduction with reason', () async {
      final success = await controller.cancelDeduction(
        'TEST-DED-001',
        reason: 'Dispute resolved by finance committee',
      );
      expect(success, isTrue);

      final updated = await repository.getDeductionById('TEST-DED-001');
      expect(updated.status, equals(DeductionStatus.cancelled));
      expect(updated.cancellationReason, equals('Dispute resolved by finance committee'));
    });
  });

  group('Deductions Module Widget Tests', () {
    late MockDeductionsRepository dedRepo;
    late AuthController authController;

    setUp(() async {
      dedRepo = MockDeductionsRepository();
      final tokenStorage = InMemoryTokenStorage();
      authController = AuthController(MockAuthRepository(tokenStorage), SessionManager(tokenStorage));
      await authController.login('admin@cyberwise.test', 'password123');
    });

    Widget createTestApp({required Widget child, bool isDark = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          Provider<DeductionsRepository>.value(value: dedRepo),
          ChangeNotifierProvider(create: (_) => DeductionsController(dedRepo)),
        ],
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('DeductionsListScreen renders financial KPI cards, subtabs, and table', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 800));
      await tester.pumpWidget(createTestApp(child: const DeductionsListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Payroll Deductions Management'), findsOneWidget);
      expect(find.text('Scheduled Deductions'), findsAtLeastNWidgets(1));
      expect(find.text('Applied in Payroll'), findsOneWidget);
      expect(find.text('Advance Recoveries'), findsOneWidget);
      expect(find.text('Workforce Penalties'), findsOneWidget);
      expect(find.text('All Deductions'), findsOneWidget);
      expect(find.text('Alex Vance (Test)'), findsOneWidget);
    });

    testWidgets('DeductionDetailsDialog renders breakdown, advance links, and cancellation in Dark theme', (tester) async {
      final sampleDed = await dedRepo.getDeductionById('TEST-DED-001');

      await tester.binding.setSurfaceSize(const Size(1366, 850));
      await tester.pumpWidget(
        createTestApp(
          child: DeductionDetailsDialog(deduction: sampleDed),
          isDark: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alex Vance (Test)'), findsOneWidget);
      expect(find.text('Deduction Amount'), findsOneWidget);
      expect(find.text('Payroll Period'), findsOneWidget);
      expect(find.text('Linked Salary Advance Schedule'), findsOneWidget);
    });

    testWidgets('DeductionFormDialog validates required fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 800));
      await tester.pumpWidget(
        createTestApp(
          child: DeductionFormDialog(
            onCreate: (ded) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Discretionary Deduction'), findsOneWidget);

      await tester.tap(find.text('Schedule Deduction'));
      await tester.pumpAndSettle();

      expect(find.text('Employee name is required'), findsOneWidget);
    });
  });
}
