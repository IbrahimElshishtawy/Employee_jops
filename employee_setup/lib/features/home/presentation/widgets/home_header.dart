import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/notification_badge.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(currentEmployeeProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final isDark = context.isDark;

    final now = DateTime.now();
    final hour = now.hour;
    final greeting = (hour >= 5 && hour < 12)
        ? context.tr('home.greeting_morning')
        : context.tr('home.greeting_evening');

    final firstName = employee?.name.split(' ').first ?? 'إبراهيم';

    return Row(
      children: [
        // Employee Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: Center(
              child: Text(
                firstName.isNotEmpty ? firstName[0] : 'E',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Greeting & Live Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting، $firstName 👋',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                now.toFormattedDate(context.l10n.locale.languageCode),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),

        // Notification Bell Icon with Badge
        NotificationBadge(
          count: unreadCount,
          onTap: () => context.go('/notifications'),
        ),
      ],
    );
  }
}
