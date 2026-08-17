import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/models/app_notification.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final String notificationId;
  final AppNotification? notification;

  const NotificationDetailsScreen({
    super.key,
    required this.notificationId,
    this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final notif = notification ??
        AppNotification(
          id: notificationId,
          title: 'تفاصيل الإشعار',
          message: 'محتوى الإشعار وتفاصيله الكاملة.',
          category: NotificationCategory.system,
          createdAt: DateTime.now(),
          isRead: true,
        );

    return Scaffold(
      appBar: const AppHeader(
        title: 'تفاصيل التنبيه',
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceVariantDark : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getCategoryName(notif.category),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Text(
                        notif.createdAt.toFormattedDateTime(),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notif.message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (notif.actionRoute != null) ...[
              const SizedBox(height: 24),
              AppButton.primary(
                label: 'عرض الطلب المرتبط',
                icon: Icons.open_in_new_rounded,
                onPressed: () => context.push(notif.actionRoute!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCategoryName(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.hrMessage:
        return 'رسائل الموارد البشرية (HR)';
      case NotificationCategory.requestUpdate:
        return 'تحديثات الطلبات';
      case NotificationCategory.deduction:
        return 'الخصومات والمستحقات';
      case NotificationCategory.attendance:
        return 'الحضور والانصراف';
      case NotificationCategory.advance:
        return 'السُلف المالية';
      case NotificationCategory.system:
        return 'تنبيهات النظام';
    }
  }
}
