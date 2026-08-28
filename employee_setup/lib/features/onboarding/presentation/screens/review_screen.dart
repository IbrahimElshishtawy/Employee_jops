import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/onboarding_provider.dart';
import '../widgets/onboarding_header.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  Future<void> _handleConfirmAndContinue() async {
    final formState = ref.read(onboardingProvider);
    if (formState.isSubmitting) return;

    final success = await ref.read(onboardingProvider.notifier).completeProfile();
    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.home);
    } else {
      final error = ref.read(onboardingProvider).errorMessage ??
          context.tr('auth.error_generic');
      context.showSnackBar(error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final formState = ref.watch(onboardingProvider);
    final employee = ref.watch(authProvider).employee;

    final fullName = formState.fullName.isNotEmpty
        ? formState.fullName
        : (employee?.googleName ?? employee?.name ?? '');
    final email = formState.email.isNotEmpty
        ? formState.email
        : (employee?.googleEmail ?? employee?.email ?? '');
    final phone = formState.phone.isNotEmpty
        ? formState.phone
        : (employee?.phone ?? '');
    final jobTitle = formState.jobTitle.isNotEmpty
        ? formState.jobTitle
        : (employee?.jobTitle ?? '');
    final department = formState.department.isNotEmpty
        ? formState.department
        : (employee?.department ?? '');

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 3 Header
                    OnboardingHeader(
                      currentStep: 3,
                      totalSteps: 3,
                      title: context.tr('onboarding.step3_title'),
                      subtitle: context.tr('onboarding.step3_subtitle'),
                      showBack: true,
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.onboardingWork);
                        }
                      },
                    ),
                    const SizedBox(height: 28),

                    // Section 1: Basic Information Card
                    _buildSectionCard(
                      context: context,
                      isDark: isDark,
                      title: context.tr('onboarding.step1_title'),
                      icon: Icons.person_outline_rounded,
                      onEdit: () {
                        context.go(AppRoutes.onboardingPersonal);
                      },
                      items: [
                        _ReviewItem(
                          label: context.tr('onboarding.full_name'),
                          value: fullName,
                          icon: Icons.badge_outlined,
                        ),
                        _ReviewItem(
                          label: context.tr('onboarding.email'),
                          value: email,
                          icon: Icons.mail_outline_rounded,
                          isVerified: true,
                        ),
                        _ReviewItem(
                          label: context.tr('onboarding.phone'),
                          value: phone,
                          icon: Icons.phone_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section 2: Job & Department Card
                    _buildSectionCard(
                      context: context,
                      isDark: isDark,
                      title: context.tr('onboarding.step2_title'),
                      icon: Icons.work_outline_rounded,
                      onEdit: () {
                        context.go(AppRoutes.onboardingWork);
                      },
                      items: [
                        _ReviewItem(
                          label: context.tr('onboarding.job_title'),
                          value: jobTitle,
                          icon: Icons.assignment_ind_outlined,
                        ),
                        _ReviewItem(
                          label: context.tr('onboarding.department'),
                          value: department,
                          icon: Icons.domain_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: AppButton(
                label: context.tr('onboarding.confirm_continue'),
                isLoading: formState.isSubmitting,
                onPressed: formState.isSubmitting ? null : _handleConfirmAndContinue,
                isFullWidth: true,
                height: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<_ReviewItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title and Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(context.tr('onboarding.edit_action')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Items
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textMutedDark : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.value.isNotEmpty ? item.value : '—',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (item.isVerified) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: AppColors.success,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Google',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem {
  final String label;
  final String value;
  final IconData icon;
  final bool isVerified;

  const _ReviewItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isVerified = false,
  });
}
