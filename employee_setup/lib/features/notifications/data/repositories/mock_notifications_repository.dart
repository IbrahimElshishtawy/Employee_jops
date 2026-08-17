import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mock/mock_database.dart';
import '../../../../core/mock/seeds/notification_seeds.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class MockNotificationsRepository implements NotificationsRepository {
  final Ref? _ref;

  MockNotificationsRepository([Object? source])
    : _ref = source is Ref ? source : null {
    if (_ref == null) {
      fallbackMockDatabaseNotifier.resetAll();
    }
  }

  MockDatabaseNotifier get _db =>
      _ref?.read(mockDatabaseProvider.notifier) ?? fallbackMockDatabaseNotifier;
  MockDatabase get _state =>
      _ref?.read(mockDatabaseProvider) ?? fallbackMockDatabaseNotifier.snapshot;

  @override
  Future<List<AppNotification>> getNotifications(String employeeId) async {
    return _state.notifications.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<int> getUnreadCount(String employeeId) async {
    return _state.unreadNotificationsCount;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    _db.markNotificationRead(notificationId);
  }

  @override
  Future<void> markAllAsRead(String employeeId) async {
    _db.markAllNotificationsRead();
  }

  @override
  Future<void> addNotification(AppNotification notification) async {
    _db.addNotification(notification);
  }

  @override
  Future<void> resetToDefaultMock() async {
    // Handled by MockDatabaseNotifier.resetDataKeepSession()
  }
}
