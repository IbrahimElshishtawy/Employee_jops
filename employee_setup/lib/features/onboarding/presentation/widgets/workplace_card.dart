import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';

/// Clean, corporate card showcasing the employee's assigned workplace.
class WorkplaceCard extends StatelessWidget {
  final String title;
  final String city;
  final String fullAddress;

  const WorkplaceCard({
    super.key,
    this.title = 'CyberWise IE - Test Office',
    this.city = 'القاهرة، مصر',
    this.fullAddress = 'شارع النيل، البرج الشرقي، القاهرة، مصر',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Location Icon + Branch Name + Assigned Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      city,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('onboarding.workplace_assigned'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 14),

          // Full Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.map_outlined,
                size: 16,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fullAddress,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
