import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/request_type.dart';

class RequestTypeSelector extends StatelessWidget {
  final List<RequestType> requestTypes;
  final String? selectedTypeId;
  final ValueChanged<String> onSelected;

  const RequestTypeSelector({
    super.key,
    required this.requestTypes,
    required this.selectedTypeId,
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
          isArabic ? 'نوع الطلب' : 'Request Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedTypeId,
              hint: Text(
                isArabic ? 'اختر نوع الطلب...' : 'Select request type...',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                ),
              ),
              dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              items: requestTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type.id,
                  child: Text(
                    type.localizedName(isArabic),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onSelected(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
