import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Premium Corporate App Logo / Mark for authentication and branded headers.
class AppLogo extends StatelessWidget {
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 76.0,
    this.iconSize = 40.0,
    this.borderRadius = 22.0,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
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
          Icons.business_center_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}
