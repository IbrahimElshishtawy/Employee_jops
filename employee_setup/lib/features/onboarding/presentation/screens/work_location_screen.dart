import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/onboarding_provider.dart';
import '../widgets/hr_contact_card.dart';
import '../widgets/location_permission_card.dart';
import '../widgets/onboarding_header.dart';
import '../widgets/workplace_card.dart';

class WorkLocationScreen extends ConsumerStatefulWidget {
  const WorkLocationScreen({super.key});

  @override
  ConsumerState<WorkLocationScreen> createState() => _WorkLocationScreenState();
}

class _WorkLocationScreenState extends ConsumerState<WorkLocationScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Work location is predefined by company HR — employee cannot change it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).setStep3Data(
            workLocationId: AppConstants.mockWorkLocationId,
            biometricEnabled: false,
          );
    });
  }

  Future<void> _handleCompleteSetup() async {
    setState(() => _isSubmitting = true);

    try {
      // Complete onboarding and update employee record
      await ref.read(onboardingProvider.notifier).completeOnboarding();
      if (!mounted) return;

      context.go(AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.showSnackBar(
        context.tr('common.error'),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

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
                    // Unified Header
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

                    // 1. Assigned Workplace Card
                    const WorkplaceCard(),
                    const SizedBox(height: 18),

                    // 2. Location Permission Explainer & Action
                    const LocationPermissionCard(),
                    const SizedBox(height: 18),

                    // 3. HR Support Contact Card
                    const HrContactCard(),
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
                label: context.tr('onboarding.complete_setup'),
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _handleCompleteSetup,
                isFullWidth: true,
                height: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
