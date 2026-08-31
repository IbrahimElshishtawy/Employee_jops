import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/tracking_enums.dart';
import '../providers/location_tracking_provider.dart';

/// Reusable status card displaying current work session background location tracking status
class TrackingStatusCard extends ConsumerWidget {
  final bool compact;

  const TrackingStatusCard({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(locationTrackingProvider);
    final isDark = context.isDark;
    final isArabic = context.isArabic;

    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    switch (trackingState.trackingStatus) {
      case TrackingStatus.activeForeground:
        statusColor = AppColors.success;
        statusTitle = isArabic ? 'تتبع الموقع: نشط (في الواجهة)' : 'Location: Active (Foreground)';
        statusIcon = Icons.location_on_rounded;
        break;
      case TrackingStatus.activeBackground:
        statusColor = AppColors.success;
        statusTitle = isArabic ? 'تتبع الموقع: نشط (في الخلفية)' : 'Location: Active (Background)';
        statusIcon = Icons.my_location_rounded;
        break;
      case TrackingStatus.starting:
        statusColor = AppColors.warning;
        statusTitle = isArabic ? 'جاري بدء التتبع...' : 'Starting Tracking...';
        statusIcon = Icons.sync_rounded;
        break;
      case TrackingStatus.paused:
        statusColor = AppColors.warning;
        statusTitle = isArabic ? 'التتبع متوقف مؤقتاً' : 'Tracking Paused';
        statusIcon = Icons.pause_circle_outline_rounded;
        break;
      case TrackingStatus.error:
        statusColor = AppColors.error;
        statusTitle = isArabic ? 'تنبيه في إذن الموقع' : 'Location Alert';
        statusIcon = Icons.error_outline_rounded;
        break;
      case TrackingStatus.stopped:
        statusColor = isDark ? Colors.white38 : Colors.black38;
        statusTitle = isArabic ? 'تتبع الموقع: متوقف' : 'Location: Stopped';
        statusIcon = Icons.location_off_outlined;
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, size: 14, color: statusColor),
            const SizedBox(width: 6),
            Text(
              statusTitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trackingState.isTracking
                          ? (isArabic
                              ? 'مرتبط بجلسة العمل النشطة الحالية'
                              : 'Tied to active work session')
                          : (isArabic
                              ? 'يبدأ التتبع تلقائياً فور تسجيل الحضور'
                              : 'Starts automatically upon check-in'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (trackingState.queuedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${trackingState.queuedCount} ${isArabic ? "معلق" : "queued"}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
                    ),
                  ),
                ),
            ],
          ),
          if (trackingState.lastUpdateTime != null && trackingState.isTracking) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'آخر تحديث دوري:' : 'Last update:',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  _formatTime(trackingState.lastUpdateTime!),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
