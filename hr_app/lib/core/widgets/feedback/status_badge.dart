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

  Color _getBgColor() {
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

  Color _getTextColor() {
    switch (variant) {
      case BadgeVariant.success:
        return AppColors.success;
      case BadgeVariant.warning:
        return const Color(0xFFD97706);
      case BadgeVariant.danger:
        return AppColors.danger;
      case BadgeVariant.info:
        return AppColors.info;
      case BadgeVariant.neutral:
        return AppColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: _getBgColor(),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 0.8),
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
