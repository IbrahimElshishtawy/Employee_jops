import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class DistanceIndicator extends StatelessWidget {
  final double distanceInMeters;
  final bool isInside;

  const DistanceIndicator({
    super.key,
    required this.distanceInMeters,
    required this.isInside,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = isInside ? AppColors.success : AppColors.error;
    final bgColor = isInside
        ? (isDark ? const Color(0xFF064E3B) : AppColors.successLight)
        : (isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppDimensions.borderRadiusMedium,
        border: Border.all(
          color: isInside
              ? (isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0))
              : (isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA)),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isInside ? Icons.location_on_rounded : Icons.location_off_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInside ? 'داخل نطاق الشركة المصرح به' : 'خارج نطاق تسجيل الحضور',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isInside
                      ? 'أنت على بعد ${distanceInMeters.toStringAsFixed(1)} متر من موقع العمل'
                      : 'أنت على بعد ${distanceInMeters.toStringAsFixed(1)} متر (الحد الأقصى المسموح 4 أمتار)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
