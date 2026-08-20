import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/env_config.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';
import '../../rbac/app_role.dart';
import '../../theme/theme_controller.dart';
import '../feedback/status_badge.dart';

/// Application Top Bar
class HrTopbar extends StatelessWidget {
  final String title;
  final String userName;
  final AppRole userRole;
  final VoidCallback? onLogout;
  final VoidCallback? onMenuPressed;
  final int unreadNotificationsCount;
  final VoidCallback? onNotificationsTap;

  const HrTopbar({
    super.key,
    required this.title,
    this.userName = 'HR Administrator',
    this.userRole = AppRole.superAdmin,
    this.onLogout,
    this.onMenuPressed,
    this.unreadNotificationsCount = 0,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: AppDimensions.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: AppDimensions.space12),
          ],
          Text(title, style: AppTypography.heading3),
          const SizedBox(width: AppDimensions.space12),
          if (EnvConfig.enableMockData)
            const StatusBadge(
              label: 'DEV MOCK',
              variant: BadgeVariant.warning,
            ),
          const Spacer(),

          // Theme Toggle
          Consumer<ThemeController>(
            builder: (context, themeCtrl, _) {
              return IconButton(
                tooltip: 'Toggle Theme',
                icon: Icon(
                  themeCtrl.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20,
                ),
                onPressed: () => themeCtrl.toggleTheme(),
              );
            },
          ),
          const SizedBox(width: AppDimensions.space8),

          // Notifications
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: onNotificationsTap,
              ),
              if (unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadNotificationsCount > 9 ? '9+' : '$unreadNotificationsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppDimensions.space16),

          // User Profile Menu
          PopupMenuButton<String>(
            tooltip: 'Account Menu',
            onSelected: (value) {
              if (value == 'logout') {
                onLogout?.call();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: AppTypography.bodyBold),
                    Text(userRole.label, style: AppTypography.caption),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppDimensions.space8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: AppTypography.bodyMedium),
                    Text(userRole.label, style: AppTypography.caption),
                  ],
                ),
                const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textSecondaryLight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
