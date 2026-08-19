import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_button.dart';

/// Banner presenting either the success celebration card, error retry card, or loading spinner.
class VerificationResultBanner extends StatelessWidget {
  final bool isSuccess;
  final bool isCheckIn;
  final AttendanceFlowState flowState;
  final bool isDark;
  final bool isRtl;
  final VoidCallback onRetry;

  const VerificationResultBanner({
    super.key,
    required this.isSuccess,
    required this.isCheckIn,
    required this.flowState,
    required this.isDark,
    required this.isRtl,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isSuccess) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
          borderRadius: AppDimensions.borderRadiusLarge,
          border: Border.all(
            color: isDark ? const Color(0xFF059669) : const Color(0xFF6EE7B7),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 48,
            ),
            const SizedBox(height: 10),
            Text(
              isCheckIn
                  ? (isRtl ? 'تم تسجيل الحضور بنجاح!' : 'Check-In Recorded Successfully!')
                  : (isRtl ? 'تم تسجيل الانصراف بنجاح!' : 'Check-Out Recorded Successfully!'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.successDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateTime.now().toFormattedDate(isRtl ? 'ar' : 'en')} — ${DateTime.now().toFormattedTime()}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFA7F3D0) : AppColors.successDark,
              ),
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              label: isRtl ? 'العودة إلى الصفحة الرئيسية' : 'Return to Home Dashboard',
              icon: Icons.home_rounded,
              onPressed: () {
                context.go('/home');
              },
            ),
          ],
        ),
      );
    }

    if (flowState.processState == AttendanceProcessState.error) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight,
          borderRadius: AppDimensions.borderRadiusLarge,
          border: Border.all(
            color: isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    flowState.message ?? (isRtl ? 'تعذر إتمام العملية' : 'Verification Failed'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.errorDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton.primary(
              label: isRtl ? 'إعادة المحاولة' : 'Try Again',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      );
    }

    if (flowState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.primaryLight,
          borderRadius: AppDimensions.borderRadiusLarge,
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                flowState.message ?? (isRtl ? 'جاري التحقق...' : 'Verifying...'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
