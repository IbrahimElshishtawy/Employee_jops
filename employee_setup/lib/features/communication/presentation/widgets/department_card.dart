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
      bg = isDark ? AppColors.primary.withValues(alpha: 0.2) : AppColors.primaryLight;
      borderColor = AppColors.primary;
    } else {
      bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
      borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    }

    return AppCard(
      onTap: isDisabled || isLoading ? null : onTap,
      backgroundColor: bg,
      borderColor: borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: AppDimensions.radiusMedium,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              // 1. Compact Icon Container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.primaryLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Title & Availability Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      department.localizedName(isArabic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (department.availableEmployeesCount > 0) ...[
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${department.availableEmployeesCount}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            isArabic ? ' متاح' : ' online',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            isArabic
                                ? '${department.totalEmployeesCount} موظف'
                                : '${department.totalEmployeesCount} members',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            const Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
