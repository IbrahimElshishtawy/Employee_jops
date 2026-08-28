import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/department_request.dart';

class RequestStatusBadge extends StatelessWidget {
  final DepartmentRequestStatus status;
  final bool isSmall;

  const RequestStatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case DepartmentRequestStatus.pending:
        bg = isDark ? const Color(0xFF332A15) : AppColors.warningLight;
        fg = isDark ? const Color(0xFFFBBF24) : AppColors.warningDark;
        icon = Icons.hourglass_top_rounded;
        break;
      case DepartmentRequestStatus.accepted:
        bg = isDark ? const Color(0xFF132A3E) : AppColors.infoLight;
        fg = isDark ? const Color(0xFF60A5FA) : AppColors.infoDark;
        icon = Icons.thumb_up_alt_outlined;
        break;
      case DepartmentRequestStatus.inProgress:
        bg = isDark ? const Color(0xFF1A2A44) : const Color(0xFFEFF6FF);
        fg = isDark ? const Color(0xFF93C5FD) : AppColors.primary;
        icon = Icons.sync_rounded;
        break;
      case DepartmentRequestStatus.completed:
        bg = isDark ? const Color(0xFF133226) : AppColors.successLight;
        fg = isDark ? const Color(0xFF34D399) : AppColors.successDark;
        icon = Icons.check_circle_outline_rounded;
        break;
      case DepartmentRequestStatus.rejected:
        bg = isDark ? const Color(0xFF361818) : AppColors.errorLight;
        fg = isDark ? const Color(0xFFF87171) : AppColors.errorDark;
        icon = Icons.cancel_outlined;
        break;
      case DepartmentRequestStatus.cancelled:
        bg = isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9);
        fg = isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight;
        icon = Icons.block_flipped;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmall ? 12 : 14,
            color: fg,
          ),
          const SizedBox(width: 5),
          Text(
            status.localizedName(isArabic),
            style: TextStyle(
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
