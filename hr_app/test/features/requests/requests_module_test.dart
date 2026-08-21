import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/security/session_manager.dart';
import 'package:hr_app/core/security/token_storage.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:hr_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hr_app/features/requests/data/repositories/mock_requests_repository.dart';
import 'package:hr_app/features/requests/domain/entities/hr_request_entity.dart';
import 'package:hr_app/features/requests/presentation/controllers/requests_controller.dart';
import 'package:hr_app/features/requests/presentation/pages/requests_list_screen.dart';
import 'package:hr_app/features/requests/presentation/widgets/request_details_dialog.dart';
import 'package:hr_app/features/requests/presentation/widgets/request_review_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  group('Requests Controller Unit Tests', () {
    late MockRequestsRepository repository;
    late RequestsController controller;

    setUp(() {
      repository = MockRequestsRepository();
      controller = RequestsController(repository);
    });

    test('Initializes and loads requests and KPIs', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.requests, isNotEmpty);
      expect(controller.kpis, isNotNull);
      expect(controller.kpis!.pendingCount, greaterThanOrEqualTo(1));
    });

    test('Filters requests by search query and type', () async {
      controller.onSearch('Alex');
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.requests.every((r) => r.employeeName.contains('Alex')), isTrue);

      controller.onSearch('');
      controller.onFilterType(RequestType.permission);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.requests.every((r) => r.type == RequestType.permission), isTrue);
    });

    test('Switches between operational subtabs', () async {
      controller.setActiveTab(RequestsTab.pending);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.activeTab, equals(RequestsTab.pending));
      expect(controller.requests.every((r) => r.status == RequestStatus.pending), isTrue);

      controller.setActiveTab(RequestsTab.approved);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.requests.every((r) => r.status == RequestStatus.approved), isTrue);
    });

    test('Approves a pending request successfully', () async {
      final success = await controller.reviewRequest(
        'TEST-REQ-001',
        approve: true,
        comment: 'Approved in test',
      );
      expect(success, isTrue);

      final req = await repository.getRequestById('TEST-REQ-001');
      expect(req.status, equals(RequestStatus.approved));
      expect(req.reviewComment, equals('Approved in test'));
      expect(req.history.any((h) => h.action == 'APPROVED'), isTrue);
    });

    test('Rejects a pending request with mandatory reason', () async {
      final success = await controller.reviewRequest(
        'TEST-REQ-003',
        approve: false,
        comment: 'Conflict with scheduled on-site deployment',
      );
      expect(success, isTrue);

      final req = await repository.getRequestById('TEST-REQ-003');
      expect(req.status, equals(RequestStatus.rejected));
      expect(req.reviewComment, equals('Conflict with scheduled on-site deployment'));
      expect(req.history.any((h) => h.action == 'REJECTED'), isTrue);
    });
  });

  group('Requests Module Widget Tests', () {
    late MockRequestsRepository reqRepo;
    late AuthController authController;

    setUp(() {
      reqRepo = MockRequestsRepository();
      final tokenStorage = InMemoryTokenStorage();
      authController = AuthController(MockAuthRepository(tokenStorage), SessionManager(tokenStorage));
    });

    Widget createTestApp({required Widget child, bool isDark = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          Provider<RequestsRepository>.value(value: reqRepo),
          ChangeNotifierProvider(create: (_) => RequestsController(reqRepo)),
        ],
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('RequestsListScreen renders KPI cards, subtabs, and data table', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 800));
      await tester.pumpWidget(createTestApp(child: const RequestsListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Employee Requests & Approvals'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('All Requests'), findsOneWidget);
      expect(find.text('Pending Approval'), findsOneWidget);
      expect(find.text('Alex Vance (Test)'), findsOneWidget);
    });

    testWidgets('RequestDetailsDialog renders information and history in Dark theme', (tester) async {
      final sampleReq = await reqRepo.getRequestById('TEST-REQ-002');

      await tester.binding.setSurfaceSize(const Size(1366, 850));
      await tester.pumpWidget(
        createTestApp(
          child: RequestDetailsDialog(request: sampleReq),
          isDark: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jordan Miller (Test)'), findsOneWidget);
      expect(find.text('Request Information'), findsOneWidget);
      expect(find.text('Review Decision Outcome'), findsOneWidget);
      expect(find.text('Request Lifecycle & Audit Trail'), findsOneWidget);
    });

    testWidgets('RequestReviewDialog validates mandatory reason on rejection', (tester) async {
      final sampleReq = await reqRepo.getRequestById('TEST-REQ-001');

      await tester.binding.setSurfaceSize(const Size(1366, 800));
      await tester.pumpWidget(
        createTestApp(
          child: RequestReviewDialog(
            request: sampleReq,
            isApproval: false,
            onReview: ({required approve, comment}) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reject Request'), findsOneWidget);
      expect(find.text('Mandatory Rejection Reason'), findsOneWidget);

      // Tap confirm without text
      await tester.tap(find.text('Confirm Rejection'));
      await tester.pumpAndSettle();

      expect(find.text('A justified rejection reason is mandatory'), findsOneWidget);
    });
  });
}
