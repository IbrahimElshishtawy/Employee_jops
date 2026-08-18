import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Premium Corporate App Logo / Mark for authentication and branded headers.
class AppLogo extends StatelessWidget {
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool showShadow;
  final bool isWhiteCardStyle;

  const AppLogo({
    super.key,
    this.size = 76.0,
    this.iconSize = 40.0,
    this.borderRadius = 22.0,
    this.showShadow = true,
    this.isWhiteCardStyle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isWhiteCardStyle) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Container(
            width: size * 0.65,
            height: size * 0.65,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(borderRadius * 0.6),
            ),
            child: Icon(
              Icons.people_alt_rounded,
              size: iconSize,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          Icons.people_alt_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}
