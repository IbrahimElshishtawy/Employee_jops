import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/notification_entity.dart';

/// Live Production Notifications Repository
class ApiNotificationsRepository implements NotificationsRepository {
  final ApiClient _apiClient;

  ApiNotificationsRepository(this._apiClient);

  @override
  Future<PaginatedList<NotificationItemEntity>> getNotifications(NotificationFilter filter) async {
    try {
      final queryParams = <String, String>{
        'page': filter.page.toString(),
        'pageSize': filter.pageSize.toString(),
      };
      if (filter.searchQuery != null) queryParams['q'] = filter.searchQuery!;
      if (filter.type != null) queryParams['type'] = filter.type!.name;
      if (filter.status != null) queryParams['status'] = filter.status!.name;
      if (filter.targetType != null) queryParams['targetType'] = filter.targetType!.name;

      final response = await _apiClient.get(
        ApiEndpoints.notifications,
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) => _mapNotification(e as Map<String, dynamic>)).toList();

          return PaginatedList<NotificationItemEntity>(
            items: items,
            totalCount: json['totalCount'] as int? ?? items.length,
            page: json['page'] as int? ?? filter.page,
            pageSize: json['pageSize'] as int? ?? filter.pageSize,
            totalPages: json['totalPages'] as int? ?? 1,
          );
        },
      );

      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<NotificationItemEntity> getNotificationById(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.notifications}/$id',
        parser: (data) => _mapNotification(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<NotificationKpiSummary> getNotificationKpis() async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.notifications}/kpis',
        parser: (data) {
          final json = data as Map<String, dynamic>;
          return NotificationKpiSummary(
            totalCount: json['totalCount'] as int? ?? 0,
            sentCount: json['sentCount'] as int? ?? 0,
            scheduledCount: json['scheduledCount'] as int? ?? 0,
            unreadCount: json['unreadCount'] as int? ?? 0,
            failedCount: json['failedCount'] as int? ?? 0,
          );
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<NotificationItemEntity> createNotification(NotificationItemEntity notification) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.notifications,
        body: {
          'title': notification.title,
          'message': notification.message,
          'type': notification.type.name,
          'severity': notification.severity.name,
          'targetType': notification.targetType.name,
          'targetName': notification.targetName,
          'scheduledAt': notification.scheduledAt?.toIso8601String(),
        },
        parser: (data) => _mapNotification(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _apiClient.patch(ApiEndpoints.notificationRead(id));
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _apiClient.post(ApiEndpoints.notificationsReadAll);
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> cancelScheduledNotification(String id) async {
    try {
      await _apiClient.post('${ApiEndpoints.notifications}/$id/cancel');
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  static NotificationItemEntity _mapNotification(Map<String, dynamic> map) {
    return NotificationItemEntity(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: _parseType(map['type'] as String?),
      severity: _parseSeverity(map['severity'] as String?),
      targetType: _parseTargetType(map['targetType'] as String?),
      targetName: map['targetName'] as String?,
      targetCount: map['targetCount'] as int? ?? 0,
      createdBy: map['createdBy'] as String? ?? 'System',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      scheduledAt: map['scheduledAt'] != null ? DateTime.parse(map['scheduledAt'] as String) : null,
      sentAt: map['sentAt'] != null ? DateTime.parse(map['sentAt'] as String) : null,
      status: _parseStatus(map['status'] as String?),
      readCount: map['readCount'] as int? ?? 0,
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  static NotificationType _parseType(String? str) {
    for (final t in NotificationType.values) {
      if (t.name.toLowerCase() == (str ?? '').toLowerCase()) return t;
    }
    return NotificationType.systemAlert;
  }

  static NotificationSeverity _parseSeverity(String? str) {
    for (final s in NotificationSeverity.values) {
      if (s.name.toLowerCase() == (str ?? '').toLowerCase()) return s;
    }
    return NotificationSeverity.info;
  }

  static NotificationTargetType _parseTargetType(String? str) {
    for (final t in NotificationTargetType.values) {
      if (t.name.toLowerCase() == (str ?? '').toLowerCase()) return t;
    }
    return NotificationTargetType.allEmployees;
  }

  static NotificationStatus _parseStatus(String? str) {
    for (final s in NotificationStatus.values) {
      if (s.name.toLowerCase() == (str ?? '').toLowerCase()) return s;
    }
    return NotificationStatus.sent;
  }
}
