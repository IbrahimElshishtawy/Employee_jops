import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/department_request.dart';

class PrioritySelector extends StatelessWidget {
  final RequestPriority selectedPriority;
  final ValueChanged<RequestPriority> onSelected;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'مستوى الأولوية' : 'Priority Level',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: RequestPriority.values.map((priority) {
            final isSelected = selectedPriority == priority;
            Color activeColor;
            switch (priority) {
              case RequestPriority.low:
                activeColor = AppColors.success;
                break;
              case RequestPriority.normal:
                activeColor = AppColors.primary;
                break;
              case RequestPriority.high:
                activeColor = AppColors.error;
                break;
            }

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onSelected(priority),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor.withOpacity(isDark ? 0.25 : 0.12)
                          : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? activeColor
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: activeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          priority.localizedName(isArabic),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? activeColor
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
