import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/extensions/context_extensions.dart';

class ChatSettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;
  final bool enabled;

  const ChatSettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.value,
    required this.onChanged,
    this.showDivider = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final color = iconColor ?? AppColors.primary;

    Widget? leadingWidget;
    if (icon != null) {
      leadingWidget = Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: (enabled ? color : Colors.grey).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? color : (isDark ? Colors.grey[600] : Colors.grey[400]),
          size: 18,
        ),
      );
    }

    return Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
          secondary: leadingWidget,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                  : (isDark ? Colors.grey[500] : Colors.grey[400]),
            ),
          ),
          subtitle: subtitle != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      color: enabled
                          ? (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight)
                          : (isDark ? Colors.grey[600] : Colors.grey[400]),
                    ),
                  ),
                )
              : null,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: leadingWidget != null ? 56 : 14,
            endIndent: 14,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
      ],
    );
  }
}
