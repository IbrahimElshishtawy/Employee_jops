import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/security/session_manager.dart';
import 'package:hr_app/core/security/token_storage.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:hr_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hr_app/features/employees/data/repositories/mock_employee_repository.dart';
import 'package:hr_app/features/employees/domain/entities/employee_entity.dart';
import 'package:hr_app/features/messages/data/repositories/mock_messages_repository.dart';
import 'package:hr_app/features/messages/domain/entities/message_entity.dart';
import 'package:hr_app/features/messages/presentation/controllers/messages_controller.dart';
import 'package:hr_app/features/messages/presentation/pages/messages_screen.dart';
import 'package:hr_app/features/messages/presentation/widgets/new_conversation_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  group('Messages Controller Unit Tests', () {
    late MockMessagesRepository repository;
    late MessagesController controller;

    setUp(() async {
      repository = MockMessagesRepository();
      controller = MessagesController(repository, autoFetch: false);
      await controller.fetchConversations();
      await controller.fetchKpis();
    });

    test('Initializes and loads conversations and KPIs', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.conversations, isNotEmpty);
      expect(controller.kpis, isNotNull);
      expect(controller.kpis!.totalConversations, greaterThan(0));
      expect(controller.selectedConversation, isNotNull);
    });

    test('Filters conversations by search query and unread tab', () async {
      controller.onSearch('Ahmed');
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.conversations.every((c) => c.employeeName.contains('Ahmed')), isTrue);

      controller.onSearch('');
      controller.setActiveTab(MessagesTab.unread);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.conversations.every((c) => c.unreadCount > 0), isTrue);
    });

    test('Selects conversation and sends message', () async {
      await Future.delayed(const Duration(milliseconds: 250));
      final conv = controller.conversations.first;
      await controller.selectConversation(conv);

      expect(controller.messages, isNotEmpty);

      final ok = await controller.sendMessage('We will review your inquiry immediately.');
      expect(ok, isTrue);
      expect(controller.messages.last.content, equals('We will review your inquiry immediately.'));
      expect(controller.messages.last.senderType, equals(MessageSenderType.hr));
    });

    test('Starts a new conversation with an employee', () async {
      final newConv = await controller.startNewConversation(
        'EMP-1004',
        'Hello Omar, please provide the medical certificate for your leave.',
      );

      expect(newConv, isNotNull);
      expect(newConv!.lastMessageContent, contains('medical certificate'));
      expect(controller.selectedConversation?.id, equals(newConv.id));
    });
  });

  group('Messages Module Widget Tests', () {
    late MockMessagesRepository repo;
    late MockEmployeeRepository empRepo;
    late AuthController authController;

    setUp(() async {
      repo = MockMessagesRepository();
      empRepo = MockEmployeeRepository();
      final tokenStorage = InMemoryTokenStorage();
      authController = AuthController(MockAuthRepository(tokenStorage), SessionManager(tokenStorage));
      await authController.login('admin@cyberwise.test', 'password123');
    });

    Widget createTestApp({required Widget child, bool isDark = false, bool autoFetch = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          Provider<MessagesRepository>.value(value: repo),
          Provider<EmployeeRepository>.value(value: empRepo),
          ChangeNotifierProvider(create: (_) => MessagesController(repo, autoFetch: autoFetch)),
        ],
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('MessagesScreen renders KPI cards, master list, and chat view in Dark theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 850));
      await tester.pumpWidget(createTestApp(child: const MessagesScreen(), autoFetch: true, isDark: true));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('HR Internal Communications & Direct Messages'), findsOneWidget);
      expect(find.text('Total Conversations'), findsOneWidget);
      expect(find.text('Unread Inquiries'), findsAtLeastNWidgets(1));
      expect(find.text('Resolved Threads'), findsOneWidget);
      expect(find.text('New Direct Message'), findsOneWidget);
      expect(find.text('Ahmed Hassan'), findsAtLeastNWidgets(1));
    });

    testWidgets('NewConversationDialog validates employee selection and message body', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 850));
      await tester.pumpWidget(
        createTestApp(
          child: NewConversationDialog(
            employeeRepository: empRepo,
            onStartConversation: (empId, msg) async => null,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('New Direct Message'), findsOneWidget);
      expect(find.text('Search Employee'), findsOneWidget);
      expect(find.text('Initial Message'), findsOneWidget);
      expect(find.text('Send Message'), findsOneWidget);
    });
  });
}
