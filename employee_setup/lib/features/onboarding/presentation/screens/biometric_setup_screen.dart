import 'package:employee_setup/app/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/onboarding_provider.dart';
import '../../../../features/attendance/domain/services/biometric_service.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  bool _isAuthenticating = false;
  bool _biometricEnabled = false;

  Future<void> _handleEnableBiometric() async {
    setState(() => _isAuthenticating = true);

    try {
      final biometricService = ref.read(biometricServiceProvider);
      final result = await biometricService.authenticate(
        reason: 'تأكيد هويتك لتفعيل المصادقة البيومترية للحضور',
      );

      if (!mounted) return;
      setState(() => _isAuthenticating = false);

      if (result == BiometricAuthResult.success) {
        setState(() => _biometricEnabled = true);
        context.showSnackBar('تم تفعيل المصادقة البيومترية بنجاح');

        // Mark biometric enabled in onboarding state
        ref
            .read(onboardingProvider.notifier)
            .setStep3Data(
              workLocationId: ref.read(onboardingProvider).workLocationId,
              biometricEnabled: true,
            );

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _completeOnboarding();
        }
      } else {
        final msg = result == BiometricAuthResult.cancelled
            ? 'تم إلغاء المصادقة البيومترية'
            : result == BiometricAuthResult.notAvailable
                ? 'المصادقة البيومترية غير متاحة على هذا الجهاز'
                : 'فشلت المصادقة البيومترية، يرجى المحاولة مجددًا';
        if (mounted) context.showSnackBar(msg, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAuthenticating = false);
      context.showSnackBar('حدث خطأ: $e', isError: true);
    }
  }

  void _handleSkip() {
    // Complete onboarding without biometric
    ref
        .read(onboardingProvider.notifier)
        .setStep3Data(
          workLocationId: ref.read(onboardingProvider).workLocationId,
          biometricEnabled: false,
        );

    _completeOnboarding();
  }

  void _completeOnboarding() {
    // Triggers notifier to save to storage and update auth state
    ref.read(onboardingProvider.notifier).completeOnboarding();

    // Navigate to home — router redirect will confirm onboardingCompleted = true
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator (Complete — full width)
              Container(
                height: 4,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                localizations.onboardingBiometricTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.onboardingBiometricSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Biometric Icon
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_biometricEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'تم التفعيل',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Benefits Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: AppDimensions.borderRadiusLarge,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BenefitItem(
                      icon: Icons.lock_rounded,
                      title: 'أمان عالي',
                      description: 'بصمتك هي كلمة المرور الخاصة بك',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _BenefitItem(
                      icon: Icons.flash_on_rounded,
                      title: 'دخول سريع',
                      description: 'لا حاجة لكتابة كلمة المرور في كل مرة',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _BenefitItem(
                      icon: Icons.shield_rounded,
                      title: 'حماية إضافية',
                      description: 'تحقق من هويتك عند الوصول لبيانات حساسة',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Enable Biometric Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isAuthenticating || _biometricEnabled
                      ? null
                      : _handleEnableBiometric,
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.fingerprint_rounded),
                  label: Text(
                    _biometricEnabled
                        ? 'تم التفعيل'
                        : localizations.onboardingEnableBiometric,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.borderRadiusLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Skip Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isAuthenticating ? null : _handleSkip,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.borderRadiusLarge,
                    ),
                  ),
                  child: Text(
                    localizations.onboardingSkipBiometric,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
