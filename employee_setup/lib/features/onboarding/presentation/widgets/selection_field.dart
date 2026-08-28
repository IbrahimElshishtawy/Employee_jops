import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Modern interactive selection tile for Job Title, Department, etc.
class SelectionField extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final IconData icon;
  final String? leadingEmoji;
  final VoidCallback onTap;
  final bool hasError;
  final String? errorText;

  const SelectionField({
    super.key,
    required this.label,
    this.value,
    required this.placeholder,
    required this.icon,
    this.leadingEmoji,
    required this.onTap,
    this.hasError = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isSelected = value != null && value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Label
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),

        // Interactive Tile
        InkWell(
          onTap: onTap,
          borderRadius: AppDimensions.borderRadiusLarge,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: AppDimensions.borderRadiusLarge,
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : (isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                width: isSelected || hasError ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Leading Icon or Emoji Container
                if (leadingEmoji != null && leadingEmoji!.isNotEmpty) ...[
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : (isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariantLight),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      leadingEmoji!,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : (isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariantLight),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],

                // Selected Value or Placeholder
                Expanded(
                  child: Text(
                    isSelected ? value! : placeholder,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                          : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Directional Chevron
                Icon(
                  context.isRtl
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ],
            ),
          ),
        ),

        // Inline Error Message
        if (hasError && errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
