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
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final employee = ref.read(authProvider).employee;
    final formState = ref.read(onboardingProvider);

    final initialName = formState.fullName.isNotEmpty
        ? formState.fullName
        : (employee?.googleName ?? employee?.name ?? 'Device Test Employee');
    final initialEmail = formState.email.isNotEmpty
        ? formState.email
        : (employee?.googleEmail ?? employee?.email ?? 'employee.test@example.com');
    final initialPhone = formState.phone.isNotEmpty
        ? formState.phone
        : (employee?.phone ?? '');

    _nameController = TextEditingController(text: initialName);
    _phoneController = TextEditingController(text: initialPhone);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).setStep1Data(
            fullName: initialName,
            email: initialEmail,
            phone: initialPhone,
          );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      final formState = ref.read(onboardingProvider);
      final employee = ref.read(authProvider).employee;
      final email = formState.email.isNotEmpty
          ? formState.email
          : (employee?.googleEmail ?? employee?.email ?? '');

      ref.read(onboardingProvider.notifier).setStep1Data(
            fullName: _nameController.text.trim(),
            email: email,
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

    final displayEmail = formState.email.isNotEmpty
        ? formState.email
        : (employee?.googleEmail ?? employee?.email ?? 'employee@company.com');

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
                      // Step 1 Header
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

                      // Avatar Container with dynamic initial
                      Center(
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _nameController,
                          builder: (context, value, _) {
                            final currentName = value.text.trim();
                            final initialLetter = currentName.isNotEmpty
                                ? currentName.substring(0, 1).toUpperCase()
                                : 'E';

                            return Container(
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
                                  initialLetter,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 1. Editable Full Name (sourced from Google)
                      AppTextField(
                        label: context.tr('onboarding.full_name'),
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        hintText: 'Ahmed Mohamed Ali',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('onboarding.name_required');
                          }
                          if (value.trim().length < 2) {
                            return context.tr('onboarding.name_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // 2. Read-Only Email (Sourced from Google OAuth Identity)
                      VerifiedField(
                        label: context.tr('onboarding.email'),
                        value: displayEmail,
                        prefixIcon: Icons.mail_outline_rounded,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 4, left: 4),
                        child: Text(
                          context.tr('onboarding.email_readonly_note'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3. Phone Number (Required & Validated)
                      AppTextField(
                        label: context.tr('onboarding.phone'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        hintText: '01012345678',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('onboarding.phone_required');
                          }
                          final trimmed = value.trim();
                          final phoneRegex = RegExp(r'^\+?[0-9\s-]{9,16}$');
                          if (!phoneRegex.hasMatch(trimmed) || trimmed.replaceAll(RegExp(r'\D'), '').length < 8) {
                            return context.tr('onboarding.phone_invalid');
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
