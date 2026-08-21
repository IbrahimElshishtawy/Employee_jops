import '../../../employees/domain/entities/employee_entity.dart';

enum NotificationType {
  systemAlert('System Alert'),
  companyAnnouncement('Company Announcement'),
  attendanceReminder('Attendance Reminder'),
  holidayNotice('Holiday Notice'),
  workplaceNotice('Workplace Notice'),
  payrollNotice('Payroll Notice');

  final String label;
  const NotificationType(this.label);
}

enum NotificationSeverity { info, warning, success, danger }

enum NotificationTargetType {
  allEmployees('All Employees'),
  department('Department'),
  workplace('Workplace'),
  specificEmployees('Specific Employees');

  final String label;
  const NotificationTargetType(this.label);
}

enum NotificationStatus {
  draft('Draft'),
  scheduled('Scheduled'),
  sending('Sending'),
  sent('Sent'),
  failed('Failed'),
  cancelled('Cancelled');

  final String label;
  const NotificationStatus(this.label);
}

/// Aggregated KPI summary for notifications
class NotificationKpiSummary {
  final int totalCount;
  final int sentCount;
  final int scheduledCount;
  final int unreadCount;
  final int failedCount;

  const NotificationKpiSummary({
    required this.totalCount,
    required this.sentCount,
    required this.scheduledCount,
    required this.unreadCount,
    required this.failedCount,
  });
}

/// Core Notification Entity
class NotificationItemEntity {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationSeverity severity;
  final NotificationTargetType targetType;
  final String? targetName;
  final int targetCount;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final NotificationStatus status;
  final int readCount;
  final bool isRead;
  final List<String> deliveryChannels;

  const NotificationItemEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.severity = NotificationSeverity.info,
    this.targetType = NotificationTargetType.allEmployees,
    this.targetName,
    this.targetCount = 0,
    required this.createdBy,
    required this.createdAt,
    this.scheduledAt,
    this.sentAt,
    this.status = NotificationStatus.sent,
    this.readCount = 0,
    this.isRead = false,
    this.deliveryChannels = const ['Push', 'In-App'],
  });

  NotificationItemEntity copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationSeverity? severity,
    NotificationTargetType? targetType,
    String? targetName,
    int? targetCount,
    String? createdBy,
    DateTime? createdAt,
    DateTime? scheduledAt,
    DateTime? sentAt,
    NotificationStatus? status,
    int? readCount,
    bool? isRead,
    List<String>? deliveryChannels,
  }) {
    return NotificationItemEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      targetType: targetType ?? this.targetType,
      targetName: targetName ?? this.targetName,
      targetCount: targetCount ?? this.targetCount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      readCount: readCount ?? this.readCount,
      isRead: isRead ?? this.isRead,
      deliveryChannels: deliveryChannels ?? this.deliveryChannels,
    );
  }
}

class NotificationFilter {
  final String? searchQuery;
  final NotificationType? type;
  final NotificationStatus? status;
  final NotificationTargetType? targetType;
  final int page;
  final int pageSize;

  const NotificationFilter({
    this.searchQuery,
    this.type,
    this.status,
    this.targetType,
    this.page = 1,
    this.pageSize = 10,
  });
}

abstract class NotificationsRepository {
  Future<PaginatedList<NotificationItemEntity>> getNotifications(NotificationFilter filter);
  Future<NotificationItemEntity> getNotificationById(String id);
  Future<NotificationKpiSummary> getNotificationKpis();
  Future<NotificationItemEntity> createNotification(NotificationItemEntity notification);
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> cancelScheduledNotification(String id);
}
