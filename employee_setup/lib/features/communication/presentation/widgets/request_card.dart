import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/department_request.dart';
import 'request_status_badge.dart';

class RequestCard extends StatelessWidget {
  final DepartmentRequest request;
  final VoidCallback onTap;

  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  Color _getPriorityColor(RequestPriority priority) {
    switch (priority) {
      case RequestPriority.low:
        return const Color(0xFF10B981);
      case RequestPriority.normal:
        return const Color(0xFF3B82F6);
      case RequestPriority.high:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    final dateFormatted = DateFormat('dd MMM yyyy, hh:mm a', isArabic ? 'ar' : 'en')
        .format(request.createdAt);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderRadius: AppDimensions.radiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(request.priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '#${request.id}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              RequestStatusBadge(
                status: request.status,
                isSmall: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.localizedRequestType(isArabic),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.business_rounded,
                size: 14,
                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                request.localizedDepartment(isArabic),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isArabic ? 'الأولوية:' : 'Priority:'} ${request.priority.localizedName(isArabic)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          if (request.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormatted,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              Icon(
                isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
