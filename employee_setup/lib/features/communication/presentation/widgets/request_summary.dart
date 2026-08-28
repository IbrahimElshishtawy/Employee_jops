import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/department_request.dart';
import '../../domain/entities/request_type.dart';

class RequestSummary extends StatelessWidget {
  final Department? department;
  final RequestType? requestType;
  final RequestPriority priority;
  final String message;
  final String? locationContext;

  const RequestSummary({
    super.key,
    required this.department,
    required this.requestType,
    required this.priority,
    required this.message,
    this.locationContext,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    return AppCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: isDark
          ? AppColors.surfaceVariantDark.withOpacity(0.5)
          : AppColors.backgroundLight,
      borderRadius: AppDimensions.radiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.summarize_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                isArabic ? 'ملخص الطلب قبل الإرسال' : 'Request Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildRow(
            label: isArabic ? 'القسم المستهدف:' : 'Department:',
            value: department?.localizedName(isArabic) ?? '-',
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _buildRow(
            label: isArabic ? 'نوع الطلب:' : 'Request Type:',
            value: requestType?.localizedName(isArabic) ?? '-',
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _buildRow(
            label: isArabic ? 'مستوى الأولوية:' : 'Priority:',
            value: priority.localizedName(isArabic),
            isDark: isDark,
          ),
          if (locationContext != null && locationContext!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildRow(
              label: isArabic ? 'الموقع / السياق:' : 'Location/Context:',
              value: locationContext!,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
