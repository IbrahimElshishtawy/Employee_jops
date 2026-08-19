import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/work_schedule.dart';

class WorkScheduleCard extends ConsumerWidget {
  const WorkScheduleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(workScheduleProvider);
    final shiftStatus = ref.watch(workScheduleShiftStatusProvider);
    final scheduleService = ref.watch(workScheduleServiceProvider);
    final isDark = context.isDark;
    final isArabic = context.isArabic;

    final summaryText = scheduleService.getScheduleSummaryMessage(
      schedule,
      isArabic: isArabic,
    );

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (shiftStatus.type) {
      case ShiftStatusType.offDay:
        statusColor = isDark
            ? AppColors.textMutedDark
            : AppColors.textSecondaryLight;
        statusBgColor = isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight;
        statusIcon = Icons.event_busy_rounded;
        break;
      case ShiftStatusType.beforeShift:
        statusColor = AppColors.info;
        statusBgColor = isDark
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
            : AppColors.primaryLight;
        statusIcon = Icons.schedule_rounded;
        break;
      case ShiftStatusType.withinShift:
        statusColor = AppColors.success;
        statusBgColor = isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.3)
            : AppColors.successLight;
        statusIcon = Icons.work_history_rounded;
        break;
      case ShiftStatusType.afterShift:
        statusColor = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;
        statusBgColor = isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight;
        statusIcon = Icons.done_all_rounded;
        break;
    }

    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.access_alarm_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Text(
                    context.tr('attendance.work_schedule_title'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${context.tr('attendance.grace_period_label')}: ${schedule.gracePeriodMinutes} ${context.tr('common.minutes')}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Shift Hours Box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: AppDimensions.borderRadiusMedium,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('attendance.shift_hours_label'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${schedule.formattedStartTime} — ${schedule.formattedEndTime}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '8 ${context.tr('common.hours')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Shift Live Status Banner
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
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summaryText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
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
