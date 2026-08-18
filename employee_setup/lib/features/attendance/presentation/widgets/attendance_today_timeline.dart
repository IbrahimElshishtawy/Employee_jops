import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_card.dart';

class AttendanceTodayTimeline extends ConsumerWidget {
  const AttendanceTodayTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(attendanceSummaryProvider);
    final isDark = context.isDark;

    final checkIn = summary.checkIn;
    final checkOut = summary.checkOut;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('attendance.timeline_title'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline Items
          // 1. Check-In Milestone
          _TimelineTile(
            title: context.tr('attendance.timeline_checkin'),
            time: checkIn != null ? checkIn.timestamp.toFormattedTime() : '--:--',
            subtitle: checkIn != null
                ? 'موثق بالبصمة • على بعد ${checkIn.distanceFromOffice.toStringAsFixed(1)} م'
                : 'في انتظار تسجيل الحضور',
            isCompleted: checkIn != null,
            isCurrent: checkIn == null,
            icon: Icons.login_rounded,
            color: AppColors.success,
            isLast: false,
          ),

          // 2. Active Session Indicator (only when checked in but not checked out)
          if (checkIn != null && checkOut == null) ...[
            _TimelineTile(
              title: context.tr('attendance.timeline_working'),
              time: 'نشط الآن',
              subtitle: 'جلسة العمل جارية حاليًا في مقر الشركة',
              isCompleted: true,
              isCurrent: true,
              icon: Icons.access_time_filled_rounded,
              color: AppColors.warning,
              isLast: false,
            ),
          ],

          // 3. Check-Out Milestone
          _TimelineTile(
            title: context.tr('attendance.timeline_checkout'),
            time: checkOut != null ? checkOut.timestamp.toFormattedTime() : '--:--',
            subtitle: checkOut != null
                ? 'موثق بالبصمة • على بعد ${checkOut.distanceFromOffice.toStringAsFixed(1)} م'
                : (checkIn != null ? 'في انتظار تسجيل الانصراف عند الانتهاء' : '--'),
            isCompleted: checkOut != null,
            isCurrent: false,
            icon: Icons.logout_rounded,
            color: AppColors.primary,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String title;
  final String time;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final IconData icon;
  final Color color;
  final bool isLast;

  const _TimelineTile({
    required this.title,
    required this.time,
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
    required this.icon,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator line + circle
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? color
                      : (isDark ? AppColors.surfaceDark : AppColors.surfaceVariantLight),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? color
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: isCompleted
                      ? Colors.white
                      : (isDark ? Colors.white38 : AppColors.textMutedLight),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted
                        ? color.withValues(alpha: 0.5)
                        : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isCompleted
                              ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                              : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? color
                              : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
