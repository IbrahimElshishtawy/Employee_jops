import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/onboarding_provider.dart';
import '../widgets/onboarding_header.dart';
import '../widgets/verified_field.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nationalIdController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final employee = ref.read(authProvider).employee;
    final formState = ref.read(onboardingProvider);

    final initialName = formState.fullName.isNotEmpty
        ? formState.fullName
        : (employee?.name ?? 'Device Test Employee');
    final initialEmail = formState.email.isNotEmpty
        ? formState.email
        : (employee?.email ?? 'employee.test@example.com');
    final initialNationalId = formState.nationalId.isNotEmpty
        ? formState.nationalId
        : (employee?.nationalId ?? 'TEST-NATIONAL-ID');
    final initialPhone = formState.phone.isNotEmpty
        ? formState.phone
        : (employee?.phone ?? '01000000000');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).setStep1Data(
            fullName: initialName,
            email: initialEmail,
            nationalId: initialNationalId,
            phone: initialPhone,
          );
    });

    _nationalIdController = TextEditingController(text: initialNationalId);
    _phoneController = TextEditingController(text: initialPhone);
  }

  @override
  void dispose() {
    _nationalIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      final formState = ref.read(onboardingProvider);
      ref.read(onboardingProvider.notifier).setStep1Data(
            fullName: formState.fullName,
            email: formState.email,
            nationalId: _nationalIdController.text.trim(),
            phone: _phoneController.text.trim(),
          );

      context.push(AppRoutes.onboardingWork);
    } else {
      context.showSnackBar(
        context.tr('onboarding.required_fields_error'),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final formState = ref.watch(onboardingProvider);
    final employee = ref.watch(authProvider).employee;

    final displayName = formState.fullName.isNotEmpty
        ? formState.fullName
        : (employee?.name ?? 'Employee User');
    final displayEmail = formState.email.isNotEmpty
        ? formState.email
        : (employee?.email ?? 'employee@company.com');

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unified Onboarding Header
                      OnboardingHeader(
                        currentStep: 1,
                        totalSteps: 3,
                        title: context.tr('onboarding.step1_title'),
                        subtitle: context.tr('onboarding.step1_subtitle'),
                        showBack: true,
                        onBack: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.login);
                          }
                        },
                      ),
                      const SizedBox(height: 28),

                      // Avatar Container with subtle glow & badge
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.8),
                                    AppColors.primaryDark,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName.substring(0, 1).toUpperCase()
                                      : 'E',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? AppColors.surfaceDark : Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 1. Google Verified Full Name
                      VerifiedField(
                        label: context.tr('onboarding.full_name'),
                        value: displayName,
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 18),

                      // 2. Google Verified Email
                      VerifiedField(
                        label: context.tr('onboarding.email'),
                        value: displayEmail,
                        prefixIcon: Icons.mail_outline_rounded,
                      ),
                      const SizedBox(height: 22),

                      // 3. National ID (Editable)
                      AppTextField(
                        label: context.tr('onboarding.national_id'),
                        controller: _nationalIdController,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        hintText: '29501011234567',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('onboarding.required_fields_error');
                          }
                          if (value.trim().length < 8) {
                            return context.tr('onboarding.required_fields_error');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // 4. Phone Number (Editable)
                      AppTextField(
                        label: context.tr('onboarding.phone'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        hintText: '01012345678',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('onboarding.required_fields_error');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
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
                label: context.tr('onboarding.continue_action'),
                onPressed: _handleContinue,
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
