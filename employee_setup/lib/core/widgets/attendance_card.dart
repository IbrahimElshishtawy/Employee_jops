import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_providers.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../extensions/context_extensions.dart';
import '../extensions/date_extensions.dart';
import 'app_button.dart';
import 'app_card.dart';

class AttendanceCard extends ConsumerWidget {
  final VoidCallback? onHistoryTap;
  final VoidCallback? onDetailsTap;

  const AttendanceCard({super.key, this.onHistoryTap, this.onDetailsTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(attendanceSummaryProvider);
    final flowState = ref.watch(attendanceFlowProvider);
    final demoState = ref.watch(demoControlsProvider);
    final isDark = context.isDark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onDetailsTap,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('home.today_status'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (onDetailsTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        context.isRtl
                            ? Icons.arrow_back_ios_new_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ],
                  ],
                ),
              ),
              if (onHistoryTap != null)
                TextButton.icon(
                  onPressed: onHistoryTap,
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: Text(
                    context.tr('attendance.history'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Status Badge / Message
          () {
            final isCheckedIn = summary.hasCheckedIn;
            final isCheckedOut = summary.hasCheckedOut;

            String mainStatusText;
            Color statusColor;
            IconData statusIcon;

            if (isCheckedOut) {
              mainStatusText = context.tr('attendance.checked_out');
              statusColor = AppColors.info;
              statusIcon = Icons.check_circle_outline_rounded;
            } else if (isCheckedIn) {
              final isPending = summary.checkIn?.isOffline == true;
              mainStatusText = isPending
                  ? context.tr('attendance.pending_hr_verification')
                  : context.tr('attendance.checked_in');
              statusColor = isPending ? AppColors.warning : AppColors.success;
              statusIcon = isPending
                  ? Icons.hourglass_top_rounded
                  : Icons.check_circle_rounded;
            } else {
              mainStatusText = context.tr('attendance.not_checked_in');
              statusColor = isDark
                  ? AppColors.textMutedDark
                  : AppColors.textSecondaryLight;
              statusIcon = Icons.radio_button_unchecked_rounded;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      mainStatusText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    if (!demoState.isOnline)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF78350F)
                              : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'وضع بدون اتصال',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFFDE68A)
                                : AppColors.warningDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                () {
                  final employee = ref.watch(employeeProvider);
                  final allowedRadius = employee.allowedRadiusMeters > 0
                      ? employee.allowedRadiusMeters
                      : 4.0;
                  final isInside = demoState.simulatedDistance <= allowedRadius;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                      borderRadius: AppDimensions.borderRadiusMedium,
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isInside
                              ? Icons.location_on_rounded
                              : Icons.location_off_rounded,
                          size: 18,
                          color: isInside
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isInside
                                ? '📍 داخل نطاق موقع العمل (أنت على بعد ${demoState.simulatedDistance.toStringAsFixed(1)} م)'
                                : '⚠️ خارج نطاق موقع العمل (أنت على بعد ${demoState.simulatedDistance.toStringAsFixed(1)} م - المسموح ${allowedRadius.toInt()}م)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isInside
                                  ? (isDark
                                        ? const Color(0xFFA7F3D0)
                                        : AppColors.successDark)
                                  : (isDark
                                        ? const Color(0xFFFECACA)
                                        : AppColors.errorDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }(),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: AppDimensions.borderRadiusMedium,
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('attendance.check_in_time'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary.checkIn != null
                                  ? summary.checkIn!.timestamp.toFormattedTime()
                                  : '--:--',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('attendance.check_out_time'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary.checkOut != null
                                  ? summary.checkOut!.timestamp
                                        .toFormattedTime()
                                  : '--:--',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (flowState.message != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color:
                          flowState.processState == AttendanceProcessState.error
                          ? (isDark
                                ? const Color(0xFF7F1D1D)
                                : AppColors.errorLight)
                          : (isDark
                                ? const Color(0xFF064E3B)
                                : AppColors.successLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          flowState.processState == AttendanceProcessState.error
                              ? Icons.info_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 16,
                          color:
                              flowState.processState ==
                                  AttendanceProcessState.error
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            flowState.message!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  flowState.processState ==
                                      AttendanceProcessState.error
                                  ? (isDark
                                        ? Colors.white
                                        : AppColors.errorDark)
                                  : (isDark
                                        ? Colors.white
                                        : AppColors.successDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Row(
                  children: [
                    Expanded(
                      child: AppButton.primary(
                        label: context.tr('attendance.check_in'),
                        icon: Icons.login_rounded,
                        isLoading: flowState.isLoading && !isCheckedIn,
                        onPressed: isCheckedIn || flowState.isLoading
                            ? null
                            : () => ref
                                  .read(attendanceFlowProvider.notifier)
                                  .executeCheckIn(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton.secondary(
                        label: context.tr('attendance.check_out'),
                        icon: Icons.logout_rounded,
                        isLoading:
                            flowState.isLoading && isCheckedIn && !isCheckedOut,
                        onPressed:
                            !isCheckedIn || isCheckedOut || flowState.isLoading
                            ? null
                            : () => ref
                                  .read(attendanceFlowProvider.notifier)
                                  .executeCheckOut(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }(),
        ],
      ),
    );
  }
}
