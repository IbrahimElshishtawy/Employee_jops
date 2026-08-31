import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/extensions/context_extensions.dart';

class ChatSettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final Color? leadingColor;
  final IconData? leadingIcon;

  const ChatSettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.leadingColor,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && leadingIcon != null) {
      final color = leadingColor ?? AppColors.primary;
      leadingWidget = Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(leadingIcon, color: color, size: 18),
      );
    }

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          onTap: onTap,
          leading: leadingWidget,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                )
              : null,
          trailing: trailing,
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
