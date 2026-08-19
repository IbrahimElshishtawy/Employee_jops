import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_logo.dart';

/// Top branding header for LoginScreen containing Language Selector Pill,
/// App Logo, Title, and Subtitle.
class LoginHeaderCard extends StatelessWidget {
  final VoidCallback onLanguageTap;
  final bool isArabic;

  const LoginHeaderCard({
    super.key,
    required this.onLanguageTap,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;

    return Column(
      children: [
        // Top Row: Language Selector Pill
        Align(
          alignment: isRtl ? Alignment.topLeft : Alignment.topRight,
          child: InkWell(
            onTap: onLanguageTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isArabic ? 'العربية' : 'English',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // App Logo & Headline
        const AppLogo(
          size: 80,
          iconSize: 42,
          borderRadius: 24,
          showShadow: true,
          isWhiteCardStyle: true,
        ),
        const SizedBox(height: 20),

        Text(
          'CyberWise IE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),

        Text(
          isRtl
              ? 'بوابة الموظفين الذكية والآمنة'
              : 'Smart & Secure Enterprise Employee Portal',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
