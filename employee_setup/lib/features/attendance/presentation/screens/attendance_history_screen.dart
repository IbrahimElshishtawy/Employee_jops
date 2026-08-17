import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/attendance.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attendanceHistoryProvider);
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppHeader(
        title: context.tr('attendance.history'),
        subtitle: 'سجل الحضور والانصراف',
      ),
      body: Builder(
        builder: (context) {
          final logs = historyAsync;
          if (logs.isEmpty) {
            return const EmptyState(
              title: 'لا يوجد سجل حضور حتى الآن',
              subtitle: 'سجل الحضور والانصراف',
              icon: Icons.calendar_month_outlined,
            );
          }

          return ListView.separated(
            padding: AppDimensions.pagePadding,
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              final isCheckIn = log.type == AttendanceType.checkIn;

              return AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCheckIn
                            ? (isDark
                                  ? const Color(0xFF064E3B)
                                  : AppColors.successLight)
                            : (isDark
                                  ? const Color(0xFF1E3A8A)
                                  : AppColors.primaryLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                        color: isCheckIn
                            ? AppColors.success
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isCheckIn
                                    ? context.tr('attendance.check_in')
                                    : context.tr('attendance.check_out'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              StatusBadge(
                                label: log.isOffline
                                    ? context.tr(
                                        'attendance.pending_hr_verification',
                                      )
                                    : (isCheckIn ? 'حضور موثق' : 'انصراف موثق'),
                                status: log.isOffline
                                    ? BadgeStatus.offline
                                    : BadgeStatus.approved,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.timestamp.toFormattedDateTime(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'المسافة: ${log.distanceFromOffice.toStringAsFixed(1)} م • بصمة موثقة',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
