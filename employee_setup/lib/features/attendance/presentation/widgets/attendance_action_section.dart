import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/location_result.dart';
import 'checkout_confirm_dialog.dart';

class AttendanceActionSection extends ConsumerWidget {
  const AttendanceActionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(attendanceSummaryProvider);
    final flowState = ref.watch(attendanceFlowProvider);
    final demo = ref.watch(demoControlsProvider);
    final isDark = context.isDark;

    final hasCheckedIn = summary.hasCheckedIn;
    final hasCheckedOut = summary.hasCheckedOut;
    final isLoading = flowState.isLoading;

    final locResult = flowState.locationResult;
    final isInside = locResult?.isInsideRange ?? (demo.simulatedDistance <= 4.0);
    final isPermissionDenied =
        locResult?.isPermissionDenied ?? (demo.locationMode == MockLocationMode.permissionDenied);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Flow Feedback Banner (Progress, Success, Error)
        if (flowState.message != null && flowState.message!.isNotEmpty) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: flowState.processState == AttendanceProcessState.error
                  ? (isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight)
                  : flowState.processState == AttendanceProcessState.success
                      ? (isDark ? const Color(0xFF064E3B) : AppColors.successLight)
                      : (isDark ? AppColors.surfaceVariantDark : AppColors.primaryLight),
              borderRadius: AppDimensions.borderRadiusMedium,
              border: Border.all(
                color: flowState.processState == AttendanceProcessState.error
                    ? AppColors.error
                    : flowState.processState == AttendanceProcessState.success
                        ? AppColors.success
                        : AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                else
                  Icon(
                    flowState.processState == AttendanceProcessState.error
                        ? Icons.error_outline_rounded
                        : flowState.processState == AttendanceProcessState.success
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                    size: 20,
                    color: flowState.processState == AttendanceProcessState.error
                        ? AppColors.error
                        : flowState.processState == AttendanceProcessState.success
                            ? AppColors.success
                            : AppColors.primary,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    flowState.message!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: flowState.processState == AttendanceProcessState.error
                          ? (isDark ? Colors.white : AppColors.errorDark)
                          : flowState.processState == AttendanceProcessState.success
                              ? (isDark ? Colors.white : AppColors.successDark)
                              : (isDark ? Colors.white : AppColors.primaryDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Primary Action Button
        () {
          if (isPermissionDenied) {
            return AppButton.primary(
              label: context.tr('attendance.allow_location_permission'),
              icon: Icons.location_searching_rounded,
              onPressed: () => ref.read(attendanceFlowProvider.notifier).requestLocationPermission(),
            );
          }

          if (hasCheckedOut) {
            // Workday Completed
            return AppButton.secondary(
              label: context.tr('attendance.completed_btn'),
              icon: Icons.done_all_rounded,
              onPressed: null,
            );
          }

          if (!hasCheckedIn) {
            // Check-In Mode
            return AppButton.primary(
              label: context.tr('attendance.check_in'),
              icon: Icons.fingerprint_rounded,
              isLoading: isLoading,
              onPressed: !isInside || isLoading
                  ? null
                  : () => ref.read(attendanceFlowProvider.notifier).executeCheckIn(),
            );
          }

          // Check-Out Mode
          return AppButton.primary(
            label: context.tr('attendance.check_out'),
            icon: Icons.logout_rounded,
            isLoading: isLoading,
            onPressed: !isInside || isLoading
                ? null
                : () async {
                    final confirmed = await CheckoutConfirmDialog.show(context);
                    if (confirmed) {
                      await ref.read(attendanceFlowProvider.notifier).executeCheckOut();
                    }
                  },
          );
        }(),

        // Helper guidance hint under button
        if (!hasCheckedOut && !isInside && !isPermissionDenied) ...[
          const SizedBox(height: 8),
          Text(
            context.tr('attendance.outside_range_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }
}
