import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';

class ActiveRequestsCard extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const ActiveRequestsCard({
    super.key,
    required this.activeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    if (activeCount == 0) return const SizedBox.shrink();

    return AppCard(
      onTap: onTap,
      backgroundColor: isDark
          ? const Color(0xFF1E293B)
          : const Color(0xFFEFF6FF),
      borderColor: isDark
          ? AppColors.primaryDark
          : const Color(0xFFBFDBFE),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: AppDimensions.radiusLarge,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'الطلبات التشغيلية النشطة' : 'Active Department Requests',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? 'لديك $activeCount طلبات قيد المتابعة حالياً'
                      : 'You have $activeCount active requests in progress',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$activeCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            size: 18,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ],
      ),
    );
  }
}
