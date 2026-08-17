import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final Color? iconColor;

  const NotificationBadge({
    super.key,
    required this.count,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: iconColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            size: 24,
          ),
          onPressed: onTap,
          tooltip: 'التنبيهات',
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
