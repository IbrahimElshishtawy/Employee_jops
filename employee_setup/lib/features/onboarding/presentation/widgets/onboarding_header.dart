import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Unified, corporate Onboarding Header across all 3 steps.
/// Displays RTL-aware Back navigation, Step pill, 3-segment progress bar,
/// and clear typography for Title and Subtitle.
class OnboardingHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final bool showBack;

  const OnboardingHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;

    final stepText = isRtl
        ? 'الخطوة $currentStep من $totalSteps'
        : 'STEP $currentStep OF $totalSteps';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Back button & Step Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showBack)
              InkWell(
                onTap: onBack ??
                    () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Icon(
                    isRtl
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              )
            else
              const SizedBox(width: 36, height: 36),

            // Step Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                stepText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3-Segment Progress Bar
        Row(
          children: List.generate(totalSteps, (index) {
            final isCompletedOrCurrent = index < currentStep;
            final isCurrent = index == currentStep - 1;

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index < totalSteps - 1 ? 8 : 0,
                ),
                height: 4,
                decoration: BoxDecoration(
                  color: isCompletedOrCurrent
                      ? (isCurrent
                          ? AppColors.primary
                          : AppColors.primaryDark)
                      : (isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.borderLight),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 28),

        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
