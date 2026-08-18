import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_logo.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSigningIn = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(authProvider.notifier).signInWithGoogle();
      if (!mounted) return;

      setState(() => _isSigningIn = false);

      if (success) {
        final employee = ref.read(authProvider).employee;
        if (employee != null && employee.onboardingCompleted) {
          context.go('/home');
        } else {
          context.go('/onboarding/personal');
        }
      } else {
        setState(() {
          _errorMessage = context.tr('auth.error_generic');
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        _errorMessage = context.tr('auth.error_generic');
      });
    }
  }

  void _showLanguagePicker() {
    final currentLocale = ref.read(settingsProvider).locale;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.isRtl ? 'اختر لغة التطبيق' : 'Select App Language',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  label: 'العربية (Arabic)',
                  isSelected: currentLocale.languageCode == 'ar',
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLocale(const Locale('ar'));
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  label: 'English (الإنجليزية)',
                  isSelected: currentLocale.languageCode == 'en',
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLocale(const Locale('en'));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isRtl = context.isRtl;
    final currentLocale = ref.watch(settingsProvider).locale;
    final isArabic = currentLocale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FD),
      body: Stack(
        children: [
          // ─── 1. Decorative Curved Background Blobs ───────────────────
          Positioned(
            top: -60,
            left: isRtl ? null : -60,
            right: isRtl ? -60 : null,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFDCEBFE))
                    .withValues(alpha: isDark ? 0.4 : 0.7),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: isRtl ? null : -80,
            left: isRtl ? -80 : null,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFE0EEFE))
                    .withValues(alpha: isDark ? 0.3 : 0.6),
              ),
            ),
          ),

          // ─── 2. Main Scrollable Content ──────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Row: Language Selector Pill
                      Align(
                        alignment: isRtl ? Alignment.topLeft : Alignment.topRight,
                        child: InkWell(
                          onTap: _showLanguagePicker,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.04,
                                  ),
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
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
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

                      // ─── 3. App Logo & Headline ──────────────────────
                      const AppLogo(
                        size: 80,
                        iconSize: 42,
                        borderRadius: 24,
                        showShadow: true,
                        isWhiteCardStyle: true,
                      ),
                      const SizedBox(height: 20),

                      Text(
                        context.tr('auth.welcome_back'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        isRtl
                            ? 'تسجيل الدخول إلى حسابك'
                            : 'Sign in to your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Inline Error Banner (if any)
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(isDark),
                        const SizedBox(height: 16),
                      ],

                      // ─── 4. Main White Card Container ────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : const Color(0xFFEEF2F6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.05,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Card Title
                            Text(
                              isRtl
                                  ? 'تسجيل الدخول بحساب جوجل'
                                  : 'Sign in with Google Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isRtl
                                  ? 'استخدم حساب جوجل الخاص بك للوصول إلى التطبيق'
                                  : 'Use your Google account to access the app',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Royal Blue Google Button
                            GoogleSignInButton(
                              isLoading: _isSigningIn,
                              isFilled: true,
                              label: isRtl
                                  ? 'متابعة باستخدام Google'
                                  : 'Continue with Google',
                              onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                            ),
                            const SizedBox(height: 20),

                            // 'أو' (OR) Divider Line
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : const Color(0xFFE2E8F0),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    isRtl ? 'أو' : 'OR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textMutedDark
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : const Color(0xFFE2E8F0),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Security Info Box (Light Blue Container)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF0F6FE),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.primaryDark
                                      : const Color(0xFFDBEAFE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Shield Icon Badge
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.verified_user_rounded,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Texts
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr('auth.secure_access'),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isRtl
                                              ? 'باستخدام حساب جوجل الخاص بك للوصول السريع والآمن إلى جميع خدماتك'
                                              : 'Using your Google account for secure and fast access to all services',
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.4,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ─── 5. Help & Support Link ──────────────────────
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

                      // ─── 6. Terms & Privacy Notice ───────────────────
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
                                  text: isRtl
                                      ? 'سياسة الخصوصية'
                                      : 'Privacy Policy',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: isRtl ? ' و ' : ' and ',
                                ),
                                TextSpan(
                                  text: isRtl
                                      ? 'شروط الاستخدام'
                                      : 'Terms of Service',
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF450A0A) : AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFFCA5A5) : AppColors.errorDark,
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: isDark ? const Color(0xFFFCA5A5) : AppColors.errorDark,
            ),
          ),
        ],
      ),
    );
  }
}
