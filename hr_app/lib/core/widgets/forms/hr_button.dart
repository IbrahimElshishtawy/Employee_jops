import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_typography.dart';

enum HrButtonVariant {
  primary,
  secondary,
  outline,
  danger,
  ghost,
}

/// Standard Action Button with multiple visual styles
class HrButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final HrButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const HrButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = HrButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonChild;

    if (isLoading) {
      buttonChild = const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppDimensions.space8),
          Text(label, style: AppTypography.button),
        ],
      );
    } else {
      buttonChild = Text(label, style: AppTypography.button);
    }

    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget btn;
    switch (variant) {
      case HrButtonVariant.primary:
        btn = ElevatedButton(
          onPressed: effectiveOnPressed,
          child: buttonChild,
        );
        break;
      case HrButtonVariant.secondary:
        btn = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
          onPressed: effectiveOnPressed,
          child: buttonChild,
        );
        break;
      case HrButtonVariant.danger:
        btn = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: effectiveOnPressed,
          child: buttonChild,
        );
        break;
      case HrButtonVariant.outline:
        btn = OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            side: const BorderSide(color: AppColors.borderLight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space20,
              vertical: AppDimensions.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
          ),
          onPressed: effectiveOnPressed,
          child: buttonChild,
        );
        break;
      case HrButtonVariant.ghost:
        btn = TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimaryLight,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space12,
            ),
          ),
          onPressed: effectiveOnPressed,
          child: buttonChild,
        );
        break;
    }

    if (width != null) {
      return SizedBox(width: width, child: btn);
    }
    return btn;
  }
}
