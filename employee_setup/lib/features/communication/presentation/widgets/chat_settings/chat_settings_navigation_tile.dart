import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/extensions/context_extensions.dart';
import 'chat_settings_tile.dart';

class ChatSettingsNavigationTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final String? valueText;
  final VoidCallback onTap;
  final bool showDivider;

  const ChatSettingsNavigationTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.valueText,
    required this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    return ChatSettingsTile(
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      leadingColor: iconColor,
      showDivider: showDivider,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (valueText != null) ...[
            Text(
              valueText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(
            isArabic
                ? Icons.arrow_back_ios_new_rounded
                : Icons.arrow_forward_ios_rounded,
            size: 14,
            color: isDark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
          ),
        ],
      ),
    );
  }
}
