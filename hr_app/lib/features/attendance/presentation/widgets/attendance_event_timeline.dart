import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/attendance_record.dart';

/// Vertical timeline displaying granular attendance punch lifecycle events
class AttendanceEventTimeline extends StatelessWidget {
  final List<AttendanceEvent> events;

  const AttendanceEventTimeline({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Text(
          'No granular audit events recorded for this attendance session.',
          style: AppTypography.captionOf(context),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        final iconData = _getEventIcon(event.eventType);
        final iconColor = _getEventColor(event.eventType);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Node & Connecting Line
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.25 : 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: iconColor.withValues(alpha: 0.5)),
                    ),
                    child: Icon(iconData, size: 14, color: iconColor),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.border(context),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppDimensions.space12),

              // Event Details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(event.eventType.label, style: AppTypography.bodyBold),
                          Text(
                            DateFormatter.toDisplayDateTime(event.timestamp),
                            style: AppTypography.captionOf(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getEventIcon(AttendanceEventType type) {
    switch (type) {
      case AttendanceEventType.checkInAttempted:
      case AttendanceEventType.checkOutAttempted:
        return Icons.touch_app_outlined;
      case AttendanceEventType.gpsValidated:
        return Icons.gps_fixed;
      case AttendanceEventType.geofenceValidated:
        return Icons.fence_outlined;
      case AttendanceEventType.checkInAccepted:
      case AttendanceEventType.checkOutAccepted:
        return Icons.check_circle_outline;
      case AttendanceEventType.checkInRejected:
      case AttendanceEventType.checkOutRejected:
        return Icons.cancel_outlined;
      case AttendanceEventType.manualCorrection:
        return Icons.edit_calendar_outlined;
    }
  }

  Color _getEventColor(AttendanceEventType type) {
    switch (type) {
      case AttendanceEventType.checkInAttempted:
      case AttendanceEventType.checkOutAttempted:
        return AppColors.primaryLight;
      case AttendanceEventType.gpsValidated:
        return const Color(0xFF6366F1);
      case AttendanceEventType.geofenceValidated:
        return const Color(0xFF0EA5E9);
      case AttendanceEventType.checkInAccepted:
      case AttendanceEventType.checkOutAccepted:
        return AppColors.success;
      case AttendanceEventType.checkInRejected:
      case AttendanceEventType.checkOutRejected:
        return AppColors.danger;
      case AttendanceEventType.manualCorrection:
        return AppColors.warning;
    }
  }
}
