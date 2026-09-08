import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/mock/mock_database.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class RealNotificationsRepository implements NotificationsRepository {
  final ApiClient apiClient;
  final Ref? _ref;

  RealNotificationsRepository({
    required this.apiClient,
    Ref? ref,
  }) : _ref = ref;

  MockDatabaseNotifier get _db =>
      _ref?.read(mockDatabaseProvider.notifier) ?? fallbackMockDatabaseNotifier;
  MockDatabase get _state =>
      _ref?.read(mockDatabaseProvider) ?? fallbackMockDatabaseNotifier.snapshot;

  @override
  Future<List<AppNotification>> getNotifications(String employeeId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.notifications,
        cacheDuration: const Duration(seconds: 15),
        fromData: (data) {
          if (data is List) {
            return data
                .whereType<Map<String, dynamic>>()
                .map((e) => AppNotification.fromJson(e))
                .toList();
          }
          return <AppNotification>[];
        },
      );
      if (response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
    } catch (e) {
      SecureLogger.info('RealNotificationsRepository', 'Fallback to cached notifications: $e');
    }

    return _state.notifications.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<int> getUnreadCount(String employeeId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.unreadNotificationsCount,
        cacheDuration: const Duration(seconds: 10),
      );
      if (response.data is Map<String, dynamic>) {
        final count = response.data['count'] as int?;
        if (count != null) return count;
      }
    } catch (_) {}

    return _state.unreadNotificationsCount;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    _db.markNotificationRead(notificationId);
    try {
      await apiClient.patch(ApiEndpoints.markNotificationRead(notificationId));
      apiClient.clearCache(ApiEndpoints.notifications);
    } catch (e) {
      SecureLogger.info('RealNotificationsRepository', 'Failed to mark read remotely: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String employeeId) async {
    _db.markAllNotificationsRead();
    try {
      await apiClient.patch(ApiEndpoints.markAllNotificationsRead);
      apiClient.clearCache(ApiEndpoints.notifications);
    } catch (e) {
      SecureLogger.info('RealNotificationsRepository', 'Failed to mark all read remotely: $e');
    }
  }

  @override
  Future<void> addNotification(AppNotification notification) async {
    _db.addNotification(notification);
    try {
      final notifService = _ref?.read(notificationServiceProvider);
      if (notifService != null) {
        await notifService.showNotification(
          id: notification.id.hashCode,
          title: notification.title,
          body: notification.message,
          channelId: notification.category == NotificationCategory.attendance
              ? NotificationService.attendanceChannelId
              : NotificationService.requestsChannelId,
        );
      }
    } catch (_) {}
  }

  @override
  Future<void> resetToDefaultMock() async {
    _db.resetAll();
  }
}
