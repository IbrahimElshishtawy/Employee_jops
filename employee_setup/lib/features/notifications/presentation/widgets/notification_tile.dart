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
    final isDark = context.isDark;

    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (notification.category) {
      case NotificationCategory.hrMessage:
        icon = Icons.support_agent_rounded;
        iconColor = const Color(0xFF8B5CF6);
        iconBg = isDark ? const Color(0xFF4C1D95) : const Color(0xFFEDE9FE);
        break;
      case NotificationCategory.requestUpdate:
        icon = Icons.assignment_turned_in_outlined;
        iconColor = AppColors.success;
        iconBg = isDark ? const Color(0xFF064E3B) : AppColors.successLight;
        break;
      case NotificationCategory.deduction:
        icon = Icons.money_off_rounded;
        iconColor = AppColors.error;
        iconBg = isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight;
        break;
      case NotificationCategory.attendance:
        icon = Icons.access_time_filled_rounded;
        iconColor = AppColors.primary;
        iconBg = isDark ? const Color(0xFF1E3A8A) : AppColors.primaryLight;
        break;
      case NotificationCategory.advance:
        icon = Icons.account_balance_wallet_rounded;
        iconColor = const Color(0xFF10B981);
        iconBg = isDark ? const Color(0xFF064E3B) : AppColors.successLight;
        break;
      case NotificationCategory.system:
        icon = Icons.notifications_active_outlined;
        iconColor = AppColors.warning;
        iconBg = isDark ? const Color(0xFF78350F) : AppColors.warningLight;
        break;
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      backgroundColor: notification.isRead
          ? (isDark ? AppColors.surfaceDark : Colors.white)
          : (isDark ? const Color(0xFF1E2638) : const Color(0xFFF0F7FF)),
      borderColor: notification.isRead
          ? (isDark ? AppColors.borderDark : AppColors.borderLight)
          : (isDark ? AppColors.primary : const Color(0xFFBAE6FD)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  notification.createdAt.timeAgo(context.l10n.locale.languageCode),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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
