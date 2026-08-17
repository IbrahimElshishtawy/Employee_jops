import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool hasBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppDimensions.cardPadding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AppDimensions.radiusLarge,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final border = hasBorder
        ? BorderSide(
            color: borderColor ?? (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: 1,
          )
        : BorderSide.none;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: border,
    );

    return Material(
      color: bg,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            )
          : Padding(padding: padding, child: child),
    );
  }
}
