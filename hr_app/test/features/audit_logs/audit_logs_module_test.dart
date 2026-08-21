import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/security/session_manager.dart';
import 'package:hr_app/core/security/token_storage.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/features/audit_logs/data/repositories/mock_audit_logs_repository.dart';
import 'package:hr_app/features/audit_logs/domain/entities/audit_log_entity.dart';
import 'package:hr_app/features/audit_logs/presentation/controllers/audit_logs_controller.dart';
import 'package:hr_app/features/audit_logs/presentation/pages/audit_logs_screen.dart';
import 'package:hr_app/features/audit_logs/presentation/widgets/audit_log_details_dialog.dart';
import 'package:hr_app/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:hr_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

void main() {
  group('Audit Logs Controller Unit Tests', () {
    late MockAuditLogsRepository repository;
    late AuditLogsController controller;

    setUp(() async {
      repository = MockAuditLogsRepository();
      controller = AuditLogsController(repository, autoFetch: false);
      await controller.fetchAuditLogs();
      await controller.fetchKpis();
    });

    test('Initializes and loads audit logs and KPIs', () {
      expect(controller.logs, isNotEmpty);
      expect(controller.kpis, isNotNull);
      expect(controller.kpis!.totalLogs, greaterThan(0));
      expect(controller.totalCount, greaterThan(0));
    });

    test('Filters audit logs by search query and category tab', () async {
      controller.onSearch('Youssef');
      await controller.fetchAuditLogs();
      expect(controller.logs.every((l) => l.targetSummary?.contains('Youssef') ?? false), isTrue);

      controller.onSearch('');
      controller.setActiveTab(AuditLogsTab.security);
      await controller.fetchAuditLogs();
      expect(controller.logs.every((l) => l.category == AuditActionCategory.security), isTrue);
    });

    test('Loads detailed audit log record by ID', () async {
      final log = await repository.getAuditLogById('AUD-001');
      expect(log.action, equals('LEAVE_REQUEST_APPROVED'));
      expect(log.result, equals(AuditResultStatus.success));
      expect(log.metadata['daysRequested'], equals(4));
    });
  });

  group('Audit Logs Module Widget Tests', () {
    late MockAuditLogsRepository repo;
    late AuthController authController;

    setUp(() async {
      repo = MockAuditLogsRepository();
      final tokenStorage = InMemoryTokenStorage();
      authController = AuthController(MockAuthRepository(tokenStorage), SessionManager(tokenStorage));
      await authController.login('admin@cyberwise.test', 'password123');
    });

    Widget createTestApp({required Widget child, bool isDark = false, bool autoFetch = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          Provider<AuditLogsRepository>.value(value: repo),
          ChangeNotifierProvider(create: (_) => AuditLogsController(repo, autoFetch: autoFetch)),
        ],
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('AuditLogsScreen renders StatCards, subtabs, and data table in Dark mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      await tester.pumpWidget(createTestApp(child: const AuditLogsScreen(), autoFetch: true, isDark: true));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('System Audit Logs & Security Trail'), findsOneWidget);
      expect(find.text('Total Logs'), findsOneWidget);
      expect(find.text('Security Events'), findsOneWidget);
      expect(find.text('Admin Actions'), findsOneWidget);
      expect(find.text('Failed Operations'), findsOneWidget);
      expect(find.text('All Activity'), findsOneWidget);
      expect(find.text('LEAVE_REQUEST_APPROVED'), findsOneWidget);
    });

    testWidgets('AuditLogDetailsDialog renders actor telemetry, target entity, and metadata payload', (tester) async {
      final sampleLog = await tester.runAsync(() => repo.getAuditLogById('AUD-002'));
      expect(sampleLog, isNotNull);

      await tester.binding.setSurfaceSize(const Size(1366, 900));
      await tester.pumpWidget(
        createTestApp(
          child: AuditLogDetailsDialog(log: sampleLog!),
          isDark: true,
          autoFetch: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Audit Security Record'), findsOneWidget);
      expect(find.text('SUSPICIOUS_TOKEN_REPLAY_BLOCKED'), findsOneWidget);
      expect(find.text('Security Rule Engine'), findsOneWidget);
      expect(find.text('197.34.120.89'), findsOneWidget);
      expect(find.text('Event Structured Metadata Payload'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
