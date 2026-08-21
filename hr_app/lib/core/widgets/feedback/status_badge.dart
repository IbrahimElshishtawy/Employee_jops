import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';

enum BadgeVariant {
  success,
  warning,
  danger,
  info,
  neutral,
}

/// Reusable colored status badge for entities & states
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.icon,
  });

  Color _getBgColor(bool isDark) {
    if (isDark) {
      switch (variant) {
        case BadgeVariant.success:
          return AppColors.successBgDark;
        case BadgeVariant.warning:
          return AppColors.warningBgDark;
        case BadgeVariant.danger:
          return AppColors.dangerBgDark;
        case BadgeVariant.info:
          return AppColors.infoBgDark;
        case BadgeVariant.neutral:
          return AppColors.neutralBgDark;
      }
    }
    switch (variant) {
      case BadgeVariant.success:
        return AppColors.successBg;
      case BadgeVariant.warning:
        return AppColors.warningBg;
      case BadgeVariant.danger:
        return AppColors.dangerBg;
      case BadgeVariant.info:
        return AppColors.infoBg;
      case BadgeVariant.neutral:
        return AppColors.neutralBg;
    }
  }

  Color _getTextColor(bool isDark) {
    switch (variant) {
      case BadgeVariant.success:
        return isDark ? const Color(0xFF34D399) : AppColors.success;
      case BadgeVariant.warning:
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case BadgeVariant.danger:
        return isDark ? const Color(0xFFF87171) : AppColors.danger;
      case BadgeVariant.info:
        return isDark ? const Color(0xFF38BDF8) : AppColors.info;
      case BadgeVariant.neutral:
        return isDark ? const Color(0xFF9CA3AF) : AppColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = _getTextColor(isDark);
    final bgColor = _getBgColor(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: textColor.withValues(alpha: isDark ? 0.4 : 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.captionBold.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
