import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/security/session_manager.dart';
import 'package:hr_app/core/security/token_storage.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/features/advances/data/repositories/mock_advances_repository.dart';
import 'package:hr_app/features/advances/domain/entities/advance_entity.dart';
import 'package:hr_app/features/advances/presentation/controllers/advances_controller.dart';
import 'package:hr_app/features/advances/presentation/pages/advances_list_screen.dart';
import 'package:hr_app/features/advances/presentation/widgets/advance_details_dialog.dart';
import 'package:hr_app/features/advances/presentation/widgets/advance_review_dialog.dart';
import 'package:hr_app/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:hr_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

void main() {
  group('Advances Controller Unit Tests', () {
    late MockAdvancesRepository repository;
    late AdvancesController controller;

    setUp(() {
      repository = MockAdvancesRepository();
      controller = AdvancesController(repository);
    });

    test('Initializes and loads advances and financial KPIs', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.advances, isNotEmpty);
      expect(controller.kpis, isNotNull);
      expect(controller.kpis!.totalRequestedAmount, greaterThan(0));
    });

    test('Filters advances by search query', () async {
      controller.onSearch('Alex');
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.advances.every((a) => a.employeeName.contains('Alex')), isTrue);
    });

    test('Switches between operational subtabs', () async {
      controller.setActiveTab(AdvancesTab.pending);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.activeTab, equals(AdvancesTab.pending));
      expect(controller.advances.every((a) => a.status == AdvanceStatus.pending), isTrue);

      controller.setActiveTab(AdvancesTab.approved);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.advances.every((a) => a.status == AdvanceStatus.approved), isTrue);
    });

    test('Approves an advance with approved amount and installment plan', () async {
      final success = await controller.approveAdvance(
        'TEST-ADV-001',
        approvedAmount: 500.00,
        installmentCount: 2,
        notes: 'Approved 500 USD with 2 installments',
      );
      expect(success, isTrue);

      final updated = await repository.getAdvanceById('TEST-ADV-001');
      expect(updated.status, equals(AdvanceStatus.approved));
      expect(updated.approvedAmount, equals(500.00));
      expect(updated.installmentCount, equals(2));
      expect(updated.installments.length, equals(2));
    });

    test('Rejects an advance with mandatory reason', () async {
      final success = await controller.rejectAdvance(
        'TEST-ADV-001',
        reason: 'Exceeds standard 30% monthly allowance',
      );
      expect(success, isTrue);

      final updated = await repository.getAdvanceById('TEST-ADV-001');
      expect(updated.status, equals(AdvanceStatus.rejected));
      expect(updated.rejectionReason, equals('Exceeds standard 30% monthly allowance'));
    });
  });

  group('Advances Module Widget Tests', () {
    late MockAdvancesRepository advRepo;
    late AuthController authController;

    setUp(() async {
      advRepo = MockAdvancesRepository();
      final tokenStorage = InMemoryTokenStorage();
      authController = AuthController(MockAuthRepository(tokenStorage), SessionManager(tokenStorage));
      await authController.login('admin@cyberwise.test', 'password123');
    });

    Widget createTestApp({required Widget child, bool isDark = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          Provider<AdvancesRepository>.value(value: advRepo),
          ChangeNotifierProvider(create: (_) => AdvancesController(advRepo)),
        ],
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('AdvancesListScreen renders financial KPI cards, subtabs, and table', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 800));
      await tester.pumpWidget(createTestApp(child: const AdvancesListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Salary Advances Management'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Active Disbursed'), findsOneWidget);
      expect(find.text('Approved Volume'), findsOneWidget);
      expect(find.text('Outstanding Balance'), findsOneWidget);
      expect(find.text('All Advances'), findsOneWidget);
      expect(find.text('Alex Vance (Test)'), findsOneWidget);
    });

    testWidgets('AdvanceDetailsDialog renders financial breakdown, installment schedule, and deductions in Dark theme', (tester) async {
      final sampleAdv = await advRepo.getAdvanceById('TEST-ADV-002');

      await tester.binding.setSurfaceSize(const Size(1366, 850));
      await tester.pumpWidget(
        createTestApp(
          child: AdvanceDetailsDialog(advance: sampleAdv),
          isDark: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jordan Miller (Test)'), findsOneWidget);
      expect(find.text('Requested Amount'), findsOneWidget);
      expect(find.text('Approved Amount'), findsOneWidget);
      expect(find.text('Outstanding Balance'), findsOneWidget);
      expect(find.text('Installment Repayment Schedule'), findsOneWidget);
      expect(find.text('Linked Payroll Deductions'), findsOneWidget);
    });

    testWidgets('AdvanceReviewDialog validates mandatory reason on rejection', (tester) async {
      final sampleAdv = await advRepo.getAdvanceById('TEST-ADV-001');

      await tester.binding.setSurfaceSize(const Size(1366, 800));
      await tester.pumpWidget(
        createTestApp(
          child: AdvanceReviewDialog(
            advance: sampleAdv,
            isApproval: false,
            onReview: ({required approve, approvedAmount, installmentCount, reasonOrNotes}) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reject Salary Advance'), findsOneWidget);
      expect(find.text('Mandatory Rejection Justification Reason'), findsOneWidget);

      await tester.tap(find.text('Confirm Rejection'));
      await tester.pumpAndSettle();

      expect(find.text('A justified rejection reason is mandatory'), findsOneWidget);
    });
  });
}
