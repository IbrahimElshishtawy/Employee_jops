import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/features/notifications/data/repositories/mock_notifications_repository.dart';
import 'package:employee_setup/features/notifications/domain/models/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notifications Feature Tests', () {
    late SharedPrefsStorage storage;
    late MockNotificationsRepository repo;

    setUp(() async {
      storage = SharedPrefsStorage();
      await storage.init();
      await storage.clear();
      repo = MockNotificationsRepository(storage);
    });

    test('Initial unread count is greater than 0', () async {
      final count = await repo.getUnreadCount('EMP-1024');
      expect(count, greaterThan(0));
    });

    test('Mark single notification as read decrements unread count', () async {
      final initialCount = await repo.getUnreadCount('EMP-1024');
      final list = await repo.getNotifications('EMP-1024');
      final unread = list.firstWhere((n) => !n.isRead);

      await repo.markAsRead(unread.id);
      final newCount = await repo.getUnreadCount('EMP-1024');
      expect(newCount, equals(initialCount - 1));
    });

    test('Mark all notifications as read resets unread count to 0', () async {
      await repo.markAllAsRead('EMP-1024');
      final count = await repo.getUnreadCount('EMP-1024');
      expect(count, equals(0));
    });

    test('Add new notification prepends to list and increases unread count', () async {
      final initialCount = await repo.getUnreadCount('EMP-1024');
      final newNotif = AppNotification(
        id: 'test-notif-1',
        title: 'تنبيه اختباري',
        message: 'رسالة اختبارية جديدة',
        category: NotificationCategory.system,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await repo.addNotification(newNotif);
      final count = await repo.getUnreadCount('EMP-1024');
      expect(count, equals(initialCount + 1));

      final list = await repo.getNotifications('EMP-1024');
      expect(list.first.id, equals('test-notif-1'));
    });
  });
}
