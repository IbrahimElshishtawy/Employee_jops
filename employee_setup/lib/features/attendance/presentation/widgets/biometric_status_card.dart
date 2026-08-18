import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/services/mock_biometric_service.dart';

class BiometricStatusCard extends ConsumerWidget {
  const BiometricStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(attendanceFlowProvider);
    final demo = ref.watch(demoControlsProvider);
    final isDark = context.isDark;

    final isVerifying =
        flowState.processState == AttendanceProcessState.authenticatingBiometric;
    final isFailed = demo.biometricMode == MockBiometricMode.alwaysFail &&
        flowState.processState == AttendanceProcessState.error;
    final isUnavailable =
        demo.biometricMode == MockBiometricMode.notAvailable;

    Color badgeColor;
    Color badgeBgColor;
    String badgeText;
    IconData badgeIcon;

    if (isVerifying) {
      badgeColor = AppColors.primary;
      badgeBgColor = isDark
          ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
          : AppColors.primaryLight;
      badgeText = context.tr('attendance.biometric_verifying');
      badgeIcon = Icons.fingerprint_rounded;
    } else if (isFailed) {
      badgeColor = AppColors.error;
      badgeBgColor = isDark
          ? const Color(0xFF7F1D1D).withValues(alpha: 0.4)
          : AppColors.errorLight;
      badgeText = context.tr('attendance.biometric_failed');
      badgeIcon = Icons.error_outline_rounded;
    } else if (isUnavailable) {
      badgeColor = AppColors.warning;
      badgeBgColor = isDark
          ? const Color(0xFF78350F).withValues(alpha: 0.4)
          : AppColors.warningLight;
      badgeText = context.tr('attendance.biometric_unavailable');
      badgeIcon = Icons.warning_amber_rounded;
    } else {
      badgeColor = AppColors.success;
      badgeBgColor = isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.4)
          : AppColors.successLight;
      badgeText = context.tr('attendance.biometric_ready');
      badgeIcon = Icons.verified_user_rounded;
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                  Icons.fingerprint_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('attendance.verify_identity'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Security explanation box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                  : AppColors.surfaceVariantLight,
              borderRadius: AppDimensions.borderRadiusMedium,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: isVerifying
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Icon(
                          Icons.security_rounded,
                          size: 20,
                          color: badgeColor,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('attendance.biometric_desc'),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
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
