import '../models/app_notification.dart';

abstract class NotificationsRepository {
  Future<List<AppNotification>> getNotifications(String employeeId);
  Future<int> getUnreadCount(String employeeId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String employeeId);
  Future<void> addNotification(AppNotification notification);
  Future<void> resetToDefaultMock();
}
