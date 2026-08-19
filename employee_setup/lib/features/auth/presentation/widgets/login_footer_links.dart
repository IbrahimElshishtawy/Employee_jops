import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Footer links displaying Support and Terms of Service / Privacy Policy.
class LoginFooterLinks extends StatelessWidget {
  const LoginFooterLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;

    return Column(
      children: [
        // Help & Support Link
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              isRtl ? 'هل تحتاج مساعدة؟ ' : 'Need help? ',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF64748B),
              ),
            ),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(4),
              child: Text(
                isRtl ? 'تواصل مع الدعم الفني' : 'Contact Support',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Terms & Privacy Notice
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: isDark
                  ? AppColors.textMutedDark
                  : const Color(0xFF94A3B8),
            ),
            Text.rich(
              TextSpan(
                text: isRtl
                    ? 'بالدخول أنت توافق على '
                    : 'By signing in you agree to ',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textMutedDark
                      : const Color(0xFF94A3B8),
                ),
                children: [
                  TextSpan(
                    text: isRtl ? 'سياسة الخصوصية' : 'Privacy Policy',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: isRtl ? ' و ' : ' and '),
                  TextSpan(
                    text: isRtl ? 'شروط الاستخدام' : 'Terms of Service',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
