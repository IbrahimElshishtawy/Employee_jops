import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import 'package:flutter/material.dart';

enum NotificationSeverity { info, warning, success, danger }

class HrNotification {
  final String id;
  final String title;
  final String message;
  final NotificationSeverity severity;
  final DateTime timestamp;
  final bool isRead;

  const HrNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static final List<HrNotification> _mockNotifications = [
    HrNotification(
      id: 'NOTIF-001',
      title: 'New Leave Request Submitted',
      message: 'Alex Vance submitted an annual leave request for 4 days.',
      severity: NotificationSeverity.info,
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    HrNotification(
      id: 'NOTIF-002',
      title: 'Tardiness Threshold Exceeded',
      message: 'Jordan Miller recorded 3 consecutive late check-ins this week.',
      severity: NotificationSeverity.warning,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    HrNotification(
      id: 'NOTIF-003',
      title: 'Salary Advance Approved',
      message: 'Advance #TEST-ADV-002 was successfully processed.',
      severity: NotificationSeverity.success,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('System Notifications & Alerts', style: AppTypography.heading2),
          const SizedBox(height: AppDimensions.space8),
          Text('Real-time operational alerts and submission notices.', style: AppTypography.subtitle),
          const SizedBox(height: AppDimensions.space24),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockNotifications.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final n = _mockNotifications[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppDimensions.space8),
                    decoration: BoxDecoration(
                      color: _getColor(n.severity).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_active_outlined, color: _getColor(n.severity), size: 20),
                  ),
                  title: Text(n.title, style: n.isRead ? AppTypography.body : AppTypography.bodyBold),
                  subtitle: Text(n.message, style: AppTypography.caption),
                  trailing: Text(DateFormatter.toDisplayDateTime(n.timestamp), style: AppTypography.caption),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(NotificationSeverity s) {
    switch (s) {
      case NotificationSeverity.info:
        return AppColors.info;
      case NotificationSeverity.warning:
        return AppColors.warning;
      case NotificationSeverity.success:
        return AppColors.success;
      case NotificationSeverity.danger:
        return AppColors.danger;
    }
  }
}
