import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';

class AttendanceSecurityInfoCard extends ConsumerWidget {
  const AttendanceSecurityInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoControlsProvider);
    final summary = ref.watch(attendanceSummaryProvider);
    final flowState = ref.watch(attendanceFlowProvider);
    final isDark = context.isDark;

    final hasPendingOffline =
        summary.checkIn?.isOffline == true || summary.checkOut?.isOffline == true;

    return Column(
      children: [
        // Offline Sync Notice if pending items exist
        if (hasPendingOffline) ...[
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF78350F) : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sync_problem_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('attendance.status_offline_pending'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFFEF3C7) : AppColors.warningDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('attendance.offline_alert'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFFDE68A) : AppColors.warningDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (demo.isOnline)
                  ElevatedButton(
                    onPressed: flowState.isSyncing
                        ? null
                        : () => ref
                            .read(attendanceFlowProvider.notifier)
                            .syncPendingAttendance(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: flowState.isSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.tr('attendance.sync_now'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Security Notice Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8),
            borderRadius: AppDimensions.borderRadiusMedium,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('attendance.security_note'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
