import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/app_notification.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    IconData icon;
    Color iconColor;
    Color iconBg;
    String categoryNameAr;
    String categoryNameEn;

    switch (notification.category) {
      case NotificationCategory.hrMessage:
        icon = Icons.forum_rounded;
        iconColor = const Color(0xFF8B5CF6);
        iconBg = isDark ? const Color(0xFF4C1D95).withValues(alpha: 0.3) : const Color(0xFFEDE9FE);
        categoryNameAr = 'محادثة وتواصل';
        categoryNameEn = 'Chat & HR';
        break;
      case NotificationCategory.requestUpdate:
        icon = Icons.assignment_turned_in_rounded;
        iconColor = AppColors.success;
        iconBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : AppColors.successLight;
        categoryNameAr = 'طلب تشغيلي / إجازة';
        categoryNameEn = 'Request Update';
        break;
      case NotificationCategory.deduction:
        icon = Icons.receipt_long_rounded;
        iconColor = AppColors.error;
        iconBg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : AppColors.errorLight;
        categoryNameAr = 'مالية وخصومات';
        categoryNameEn = 'Deductions';
        break;
      case NotificationCategory.attendance:
        icon = Icons.fingerprint_rounded;
        iconColor = AppColors.primary;
        iconBg = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : AppColors.primaryLight;
        categoryNameAr = 'حضور وانصراف';
        categoryNameEn = 'Attendance';
        break;
      case NotificationCategory.advance:
        icon = Icons.account_balance_wallet_rounded;
        iconColor = const Color(0xFF10B981);
        iconBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : AppColors.successLight;
        categoryNameAr = 'سلفة مالية';
        categoryNameEn = 'Advance';
        break;
      case NotificationCategory.system:
        icon = Icons.notifications_active_rounded;
        iconColor = AppColors.warning;
        iconBg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : AppColors.warningLight;
        categoryNameAr = 'النظام';
        categoryNameEn = 'System';
        break;
    }

    final categoryLabel = isArabic ? categoryNameAr : categoryNameEn;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: AppDimensions.radiusMedium,
      backgroundColor: notification.isRead
          ? (isDark ? AppColors.surfaceDark : Colors.white)
          : (isDark
              ? AppColors.primary.withValues(alpha: 0.12)
              : const Color(0xFFF0F7FF)),
      borderColor: notification.isRead
          ? (isDark ? AppColors.borderDark : AppColors.borderLight)
          : (isDark
              ? AppColors.primary.withValues(alpha: 0.5)
              : const Color(0xFFBAE6FD)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 10),

          // Content Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: notification.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      notification.createdAt
                          .timeAgo(context.l10n.locale.languageCode),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    Text(
                      categoryLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Trailing Arrow
          Icon(
            isArabic
                ? Icons.arrow_back_ios_new_rounded
                : Icons.arrow_forward_ios_rounded,
            size: 12,
            color: isDark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
          ),
        ],
      ),
    );
  }
}
