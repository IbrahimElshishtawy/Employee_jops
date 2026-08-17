import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/domain/models/employee.dart';

class EmployeeInfoCard extends StatelessWidget {
  final Employee employee;

  const EmployeeInfoCard({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(
                color: isDark ? AppColors.primary : const Color(0xFF93C5FD),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                employee.name.isNotEmpty ? employee.name[0] : 'E',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Name & Job Title
          Text(
            employee.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            employee.jobTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Metadata Grid / Badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
              borderRadius: AppDimensions.borderRadiusMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetaItem('الرقم الوظيفي', employee.id, isDark),
                Container(width: 1, height: 28, color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                _buildMetaItem('الإدارة', 'Engineering', isDark),
                Container(width: 1, height: 28, color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                _buildMetaItem('الحالة', 'نشط • Active', isDark, isSuccess: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String val, bool isDark, {bool isSuccess = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSuccess
                ? AppColors.success
                : (isDark ? Colors.white : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}
