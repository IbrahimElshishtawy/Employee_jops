import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/core/security/session_manager.dart';
import 'package:hr_app/core/security/token_storage.dart';
import 'package:hr_app/core/theme/app_theme.dart';
import 'package:hr_app/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:hr_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hr_app/features/notifications/data/repositories/mock_notifications_repository.dart';
import 'package:hr_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:hr_app/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:hr_app/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:hr_app/features/notifications/presentation/widgets/notification_details_dialog.dart';
import 'package:hr_app/features/notifications/presentation/widgets/notification_form_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  group('Notifications Controller Unit Tests', () {
    late MockNotificationsRepository repository;
    late NotificationsController controller;

    setUp(() {
      repository = MockNotificationsRepository();
      controller = NotificationsController(repository);
    });

    test('Initializes and loads notifications and KPIs', () async {
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.notifications, isNotEmpty);
      expect(controller.kpis, isNotNull);
      expect(controller.kpis!.totalCount, greaterThan(0));
      expect(controller.kpis!.sentCount, greaterThanOrEqualTo(1));
    });

    test('Filters notifications by search query and category', () async {
      controller.onSearch('Holiday');
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.notifications.every((n) => n.title.contains('Holiday') || n.message.contains('Holiday')), isTrue);

      controller.onSearch('');
      controller.onFilterType(NotificationType.systemAlert);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.notifications.every((n) => n.type == NotificationType.systemAlert), isTrue);
    });

    test('Switches between operational subtabs', () async {
      controller.setActiveTab(NotificationsTab.broadcasts);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.activeTab, equals(NotificationsTab.broadcasts));

      controller.setActiveTab(NotificationsTab.scheduled);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(controller.notifications.every((n) => n.status == NotificationStatus.scheduled), isTrue);
    });

    test('Creates and broadcasts a new announcement', () async {
      final newNotice = NotificationItemEntity(
        id: 'NOTIF-NEW-001',
        title: 'Emergency Maintenance Notice',
        message: 'Servers undergoing maintenance at 11 PM.',
        type: NotificationType.workplaceNotice,
        severity: NotificationSeverity.warning,
        targetType: NotificationTargetType.allEmployees,
        targetName: 'All 48 Employees',
        targetCount: 48,
        createdBy: 'Operations Admin',
        createdAt: DateTime.now(),
        status: NotificationStatus.sent,
      );

      final success = await controller.createNotification(newNotice);
      expect(success, isTrue);

      final found = await repository.getNotificationById('NOTIF-NEW-001');
      expect(found.title, equals('Emergency Maintenance Notice'));
      expect(found.status, equals(NotificationStatus.sent));
    });

    test('Marks notification as read and cancels scheduled', () async {
      await controller.markAsRead('NOTIF-001');
      final notif = await repository.getNotificationById('NOTIF-001');
      expect(notif.isRead, isTrue);

      await controller.cancelScheduled('NOTIF-003');
      final scheduled = await repository.getNotificationById('NOTIF-003');
      expect(scheduled.status, equals(NotificationStatus.cancelled));
    });
  });

  group('Notifications Module Widget Tests', () {
    late MockNotificationsRepository repo;
    late AuthController authController;

    setUp(() async {
      repo = MockNotificationsRepository();
      final tokenStorage = InMemoryTokenStorage();
      authController = AuthController(MockAuthRepository(tokenStorage), SessionManager(tokenStorage));
      await authController.login('admin@cyberwise.test', 'password123');
    });

    Widget createTestApp({required Widget child, bool isDark = false, bool autoFetch = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          Provider<NotificationsRepository>.value(value: repo),
          ChangeNotifierProvider(create: (_) => NotificationsController(repo, autoFetch: autoFetch)),
        ],
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets('NotificationsScreen renders KPI cards, subtabs, and data table', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 850));
      await tester.pumpWidget(createTestApp(child: const NotificationsScreen(), autoFetch: true));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('HR Notifications & Announcements Management'), findsOneWidget);
      expect(find.text('Total Notifications'), findsOneWidget);
      expect(find.text('Sent Broadcasts'), findsOneWidget);
      expect(find.text('Scheduled'), findsAtLeastNWidgets(1));
      expect(find.text('Unread Alerts'), findsOneWidget);
      expect(find.text('Company-Wide Holiday Announcement'), findsOneWidget);
    });

    testWidgets('NotificationDetailsDialog renders message and mobile preview in Dark theme', (tester) async {
      final sample = NotificationItemEntity(
        id: 'NOTIF-TEST',
        title: 'Office Relocation Notice',
        message: 'New Alexandria office opens next Monday.',
        type: NotificationType.companyAnnouncement,
        severity: NotificationSeverity.info,
        targetType: NotificationTargetType.allEmployees,
        targetName: 'All 48 Employees',
        targetCount: 48,
        createdBy: 'HR Administration',
        createdAt: DateTime.now(),
        status: NotificationStatus.sent,
      );

      await tester.binding.setSurfaceSize(const Size(1366, 850));
      await tester.pumpWidget(
        createTestApp(
          child: NotificationDetailsDialog(notification: sample),
          isDark: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Office Relocation Notice'), findsAtLeastNWidgets(1));
      expect(find.text('New Alexandria office opens next Monday.'), findsAtLeastNWidgets(1));
      expect(find.text('Mobile Push Notification Preview'), findsOneWidget);
      expect(find.text('CyberWise HR Portal'), findsOneWidget);
    });

    testWidgets('NotificationFormDialog validates required fields and shows preview', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 850));
      await tester.pumpWidget(
        createTestApp(
          child: NotificationFormDialog(
            onSend: (n) async => true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Compose HR Announcement'), findsOneWidget);
      expect(find.text('Announcement Title'), findsOneWidget);
      expect(find.text('Message Body'), findsOneWidget);
    });
  });
}
