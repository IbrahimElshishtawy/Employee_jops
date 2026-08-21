import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/notification_entity.dart';

/// Mock Notifications Repository with realistic broadcast and alert records
class MockNotificationsRepository implements NotificationsRepository {
  final List<NotificationItemEntity> _mockNotifications = [
    NotificationItemEntity(
      id: 'NOTIF-001',
      title: 'Company-Wide Holiday Announcement',
      message: 'CyberWise IE offices will be closed on Thursday for the National Holiday. Support rotations remain active.',
      type: NotificationType.holidayNotice,
      severity: NotificationSeverity.info,
      targetType: NotificationTargetType.allEmployees,
      targetName: 'All 48 Employees',
      targetCount: 48,
      createdBy: 'HR Administration',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: NotificationStatus.sent,
      readCount: 39,
      isRead: false,
    ),
    NotificationItemEntity(
      id: 'NOTIF-002',
      title: 'Monthly Attendance Policy Reminder',
      message: 'Please ensure all check-ins occur within your assigned workplace geofence radius and grace periods.',
      type: NotificationType.attendanceReminder,
      severity: NotificationSeverity.warning,
      targetType: NotificationTargetType.department,
      targetName: 'Engineering & Operations',
      targetCount: 34,
      createdBy: 'Sara Mostafa (HR Admin)',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
      status: NotificationStatus.sent,
      readCount: 31,
      isRead: true,
    ),
    NotificationItemEntity(
      id: 'NOTIF-003',
      title: 'Smart Village Data Center Maintenance',
      message: 'Scheduled power redundancy tests this Saturday. Staff on site must punch via Alexandria or HQ backup geofences.',
      type: NotificationType.workplaceNotice,
      severity: NotificationSeverity.warning,
      targetType: NotificationTargetType.workplace,
      targetName: 'Smart Village Data Center',
      targetCount: 14,
      createdBy: 'Operations Lead',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
      status: NotificationStatus.scheduled,
      readCount: 0,
      isRead: false,
    ),
    NotificationItemEntity(
      id: 'NOTIF-004',
      title: 'Tardiness Threshold Alert — Omar Khaled',
      message: 'Omar Khaled has reached 4 cumulative late arrivals this pay period.',
      type: NotificationType.systemAlert,
      severity: NotificationSeverity.danger,
      targetType: NotificationTargetType.specificEmployees,
      targetName: 'Omar Khaled (EMP-1004)',
      targetCount: 1,
      createdBy: 'System Rule Engine',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      sentAt: DateTime.now().subtract(const Duration(days: 3)),
      status: NotificationStatus.sent,
      readCount: 1,
      isRead: true,
    ),
    NotificationItemEntity(
      id: 'NOTIF-005',
      title: 'Quarterly Town Hall & Performance Reviews',
      message: 'Join leadership for Q3 operational achievements and company town hall.',
      type: NotificationType.companyAnnouncement,
      severity: NotificationSeverity.info,
      targetType: NotificationTargetType.allEmployees,
      targetName: 'All 48 Employees',
      targetCount: 48,
      createdBy: 'Executive Office',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      scheduledAt: DateTime.now().add(const Duration(days: 4)),
      status: NotificationStatus.scheduled,
      readCount: 0,
      isRead: false,
    ),
  ];

  @override
  Future<PaginatedList<NotificationItemEntity>> getNotifications(NotificationFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var results = List<NotificationItemEntity>.from(_mockNotifications);

    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = filter.searchQuery!.trim().toLowerCase();
      results = results.where((n) =>
          n.title.toLowerCase().contains(q) ||
          n.message.toLowerCase().contains(q) ||
          (n.targetName?.toLowerCase().contains(q) ?? false) ||
          n.createdBy.toLowerCase().contains(q)).toList();
    }

    if (filter.type != null) {
      results = results.where((n) => n.type == filter.type).toList();
    }

    if (filter.status != null) {
      results = results.where((n) => n.status == filter.status).toList();
    }

    if (filter.targetType != null) {
      results = results.where((n) => n.targetType == filter.targetType).toList();
    }

    final totalCount = results.length;
    final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 999);
    final startIndex = ((filter.page - 1) * filter.pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + filter.pageSize).clamp(0, totalCount);

    return PaginatedList<NotificationItemEntity>(
      items: results.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<NotificationItemEntity> getNotificationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockNotifications.firstWhere(
      (n) => n.id == id,
      orElse: () => throw Exception('Notification not found with ID: $id'),
    );
  }

  @override
  Future<NotificationKpiSummary> getNotificationKpis() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final sentCount = _mockNotifications.where((n) => n.status == NotificationStatus.sent).length;
    final scheduledCount = _mockNotifications.where((n) => n.status == NotificationStatus.scheduled).length;
    final unreadCount = _mockNotifications.where((n) => !n.isRead).length;
    final failedCount = _mockNotifications.where((n) => n.status == NotificationStatus.failed).length;

    return NotificationKpiSummary(
      totalCount: _mockNotifications.length,
      sentCount: sentCount,
      scheduledCount: scheduledCount,
      unreadCount: unreadCount,
      failedCount: failedCount,
    );
  }

  @override
  Future<NotificationItemEntity> createNotification(NotificationItemEntity notification) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _mockNotifications.insert(0, notification);
    return notification;
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _mockNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _mockNotifications[index] = _mockNotifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (int i = 0; i < _mockNotifications.length; i++) {
      _mockNotifications[i] = _mockNotifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<void> cancelScheduledNotification(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _mockNotifications[index] = _mockNotifications[index].copyWith(
        status: NotificationStatus.cancelled,
      );
    }
  }
}
