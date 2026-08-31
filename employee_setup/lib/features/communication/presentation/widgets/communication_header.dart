import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';

class CommunicationHeader extends StatelessWidget {
  final VoidCallback? onHistoryTap;

  const CommunicationHeader({super.key, this.onHistoryTap});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'التواصل والعمليات' : 'Communication & Operations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isArabic
                    ? 'تواصل مباشر مع الأقسام والزملاء وطلبات التشغيل'
                    : 'Direct department coordination & operational requests',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        if (onHistoryTap != null) ...[
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: onHistoryTap,
            icon: const Icon(Icons.history_rounded, size: 20),
            tooltip: isArabic ? 'سجل الطلبات' : 'Requests History',
          ),
        ],
      ],
    );
  }
}
