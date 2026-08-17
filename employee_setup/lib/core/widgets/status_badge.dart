import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

enum BadgeStatus {
  pending,
  approved,
  rejected,
  paid,
  cancelled,
  completed,
  insideRange,
  outsideRange,
  offline,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.status,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    switch (status) {
      case BadgeStatus.pending:
      case BadgeStatus.offline:
        bg = isDark ? const Color(0xFF78350F) : AppColors.warningLight;
        fg = isDark ? const Color(0xFFFDE68A) : AppColors.warningDark;
        break;
      case BadgeStatus.approved:
      case BadgeStatus.paid:
      case BadgeStatus.completed:
      case BadgeStatus.insideRange:
        bg = isDark ? const Color(0xFF064E3B) : AppColors.successLight;
        fg = isDark ? const Color(0xFFA7F3D0) : AppColors.successDark;
        break;
      case BadgeStatus.rejected:
      case BadgeStatus.cancelled:
      case BadgeStatus.outsideRange:
        bg = isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight;
        fg = isDark ? const Color(0xFFFECACA) : AppColors.errorDark;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppDimensions.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
