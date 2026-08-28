import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/department.dart';

class DepartmentCard extends StatelessWidget {
  final Department department;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isLoading;
  final bool isDisabled;

  const DepartmentCard({
    super.key,
    required this.department,
    this.onTap,
    this.isSelected = false,
    this.isLoading = false,
    this.isDisabled = false,
  });

  IconData _getDepartmentIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'security':
        return Icons.security_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'engineering':
        return Icons.handyman_rounded;
      case 'room_service':
        return Icons.room_service_rounded;
      case 'badge':
        return Icons.badge_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'soup_kitchen':
        return Icons.soup_kitchen_rounded;
      case 'computer':
        return Icons.computer_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'event_available':
        return Icons.event_available_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'inventory_2':
        return Icons.inventory_2_rounded;
      case 'celebration':
        return Icons.celebration_rounded;
      case 'pool':
        return Icons.pool_rounded;
      default:
        return Icons.business_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;
    final iconData = _getDepartmentIcon(department.iconName);

    Color bg;
    Color borderColor;

    if (isSelected) {
      bg = isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primaryLight;
      borderColor = AppColors.primary;
    } else {
      bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
      borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    }

    return AppCard(
      onTap: isDisabled || isLoading ? null : onTap,
      backgroundColor: bg,
      borderColor: borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      borderRadius: AppDimensions.radiusLarge,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.primaryLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconData,
                      size: 22,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : AppColors.primary),
                    ),
                  ),
                  if (department.availableEmployeesCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${department.availableEmployeesCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.successDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    department.localizedName(isArabic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      height: 1.25,
                    ),
                  ),
                  if (department.totalEmployeesCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      isArabic
                          ? '${department.totalEmployeesCount} موظف'
                          : '${department.totalEmployeesCount} members',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (isLoading)
            const Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
