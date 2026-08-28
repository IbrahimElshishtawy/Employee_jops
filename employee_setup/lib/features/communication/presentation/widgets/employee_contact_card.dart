import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/employee_contact.dart';
import 'availability_indicator.dart';

class EmployeeContactCard extends StatelessWidget {
  final EmployeeContact contact;
  final VoidCallback? onTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onRequestTap;

  const EmployeeContactCard({
    super.key,
    required this.contact,
    this.onTap,
    this.onChatTap,
    this.onRequestTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderRadius: AppDimensions.radiusLarge,
      child: Row(
        children: [
          // Avatar with online dot
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.primaryLight,
                child: Text(
                  contact.fullName.isNotEmpty
                      ? contact.fullName
                          .split(' ')
                          .take(2)
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .join()
                          .toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: isArabic ? null : 0,
                left: isArabic ? 0 : null,
                child: AvailabilityIndicator(
                  availability: contact.availability,
                  showText: false,
                  dotSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Employee Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.fullName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  contact.localizedJobTitle(isArabic),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                AvailabilityIndicator(
                  availability: contact.availability,
                  showText: true,
                ),
              ],
            ),
          ),

          // Action buttons or chevron
          if (onChatTap != null || onRequestTap != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onChatTap != null && contact.canChat)
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    color: AppColors.primary,
                    tooltip: isArabic ? 'محادثة' : 'Chat',
                    onPressed: onChatTap,
                  ),
                if (onRequestTap != null && contact.canCreateRequest)
                  IconButton(
                    icon: const Icon(Icons.assignment_add),
                    color: AppColors.info,
                    tooltip: isArabic ? 'طلب' : 'Request',
                    onPressed: onRequestTap,
                  ),
              ],
            )
          else
            Icon(
              isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
        ],
      ),
    );
  }
}
