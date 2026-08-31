import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_card.dart';

class TodayAttendanceStatusCard extends ConsumerWidget {
  const TodayAttendanceStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(attendanceSummaryProvider);
    final demo = ref.watch(demoControlsProvider);
    final isDark = context.isDark;

    final hasCheckedIn = summary.hasCheckedIn;
    final hasCheckedOut = summary.hasCheckedOut;
    final isPendingOffline = summary.checkIn?.isOffline == true;

    // Determine status badge properties
    String statusTitle;
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    if (hasCheckedOut) {
      statusTitle = context.tr('attendance.status_workday_completed');
      statusColor = AppColors.info;
      statusBgColor = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : AppColors.primaryLight;
      statusIcon = Icons.task_alt_rounded;
    } else if (hasCheckedIn) {
      if (isPendingOffline) {
        statusTitle = context.tr('attendance.status_offline_pending');
        statusColor = AppColors.warning;
        statusBgColor = isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : AppColors.warningLight;
        statusIcon = Icons.cloud_off_rounded;
      } else {
        statusTitle = context.tr('attendance.status_currently_working');
        statusColor = AppColors.success;
        statusBgColor = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : AppColors.successLight;
        statusIcon = Icons.hourglass_bottom_rounded;
      }
    } else {
      statusTitle = context.tr('attendance.status_not_checked_in');
      statusColor = isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight;
      statusBgColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
      statusIcon = Icons.radio_button_unchecked_rounded;
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceVariantDark : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('home.today_status'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!demo.isOnline) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF78350F) : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.tr('attendance.offline_badge'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFFDE68A) : AppColors.warningDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Status Banner Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: AppDimensions.borderRadiusMedium,
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Check-In & Check-Out Times Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark.withValues(alpha: 0.5) : AppColors.surfaceVariantLight,
              borderRadius: AppDimensions.borderRadiusMedium,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                // Check-In Box
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasCheckedIn
                              ? (isDark ? const Color(0xFF064E3B) : AppColors.successLight)
                              : (isDark ? AppColors.surfaceDark : Colors.white),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.login_rounded,
                          size: 18,
                          color: hasCheckedIn ? AppColors.success : (isDark ? Colors.white38 : AppColors.textMutedLight),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('attendance.check_in_time'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary.checkIn != null
                                  ? summary.checkIn!.timestamp.toFormattedTime()
                                  : '--:--',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: hasCheckedIn
                                    ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 1,
                  height: 36,
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                ),
                const SizedBox(width: 12),

                // Check-Out Box
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasCheckedOut
                              ? (isDark ? const Color(0xFF1E3A8A) : AppColors.primaryLight)
                              : (isDark ? AppColors.surfaceDark : Colors.white),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: hasCheckedOut ? AppColors.primary : (isDark ? Colors.white38 : AppColors.textMutedLight),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('attendance.check_out_time'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary.checkOut != null
                                  ? summary.checkOut!.timestamp.toFormattedTime()
                                  : '--:--',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: hasCheckedOut
                                    ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
