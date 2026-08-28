import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/employee_contact.dart';
import 'availability_indicator.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final EmployeeContact contact;
  final VoidCallback onBack;

  const ChatAppBar({
    super.key,
    required this.contact,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final isDark = context.isDark;

    return AppBar(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        onPressed: onBack,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
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
                    fontSize: 12,
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
                  dotSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                Text(
                  contact.localizedJobTitle(isArabic),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          height: 1,
        ),
      ),
    );
  }
}
