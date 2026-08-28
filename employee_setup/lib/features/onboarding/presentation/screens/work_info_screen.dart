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
import '../widgets/selection_bottom_sheet.dart';
import '../widgets/selection_field.dart';

class WorkInfoScreen extends ConsumerStatefulWidget {
  const WorkInfoScreen({super.key});

  @override
  ConsumerState<WorkInfoScreen> createState() => _WorkInfoScreenState();
}

class _WorkInfoScreenState extends ConsumerState<WorkInfoScreen> {
  String? _selectedJobTitle;
  String? _selectedDepartment;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingProvider);
    final employee = ref.read(authProvider).employee;
    final catalog = ref.read(onboardingCatalogProvider);

    final empJobTitle = employee?.jobTitle;
    final empDept = employee?.department;

    _selectedJobTitle = formState.jobTitle.isNotEmpty
        ? formState.jobTitle
        : (empJobTitle != null && catalog.jobTitles.contains(empJobTitle)
            ? empJobTitle
            : null);

    _selectedDepartment = formState.department.isNotEmpty
        ? formState.department
        : (empDept != null && catalog.departments.contains(empDept)
            ? empDept
            : null);
  }

  void _openJobTitlePicker() async {
    final catalog = ref.read(onboardingCatalogProvider);
    final items = catalog.jobTitles
        .map((t) => SelectionItem(
              id: t,
              title: t,
              icon: Icons.badge_outlined,
            ))
        .toList();

    final result = await SelectionBottomSheet.show(
      context: context,
      title: context.tr('onboarding.select_job_title'),
      items: items,
      selectedId: _selectedJobTitle,
    );

    if (result != null) {
      setState(() => _selectedJobTitle = result.id);
    }
  }

  void _openDepartmentPicker() async {
    final catalog = ref.read(onboardingCatalogProvider);
    final items = catalog.departments
        .map((d) => SelectionItem(
              id: d,
              title: d,
              icon: Icons.corporate_fare_rounded,
            ))
        .toList();

    final result = await SelectionBottomSheet.show(
      context: context,
      title: context.tr('onboarding.select_department'),
      items: items,
      selectedId: _selectedDepartment,
    );

    if (result != null) {
      setState(() => _selectedDepartment = result.id);
    }
  }

  void _handleContinue() {
    setState(() => _submitted = true);

    if (_selectedJobTitle == null || _selectedJobTitle!.trim().isEmpty) {
      context.showSnackBar(
        context.tr('onboarding.job_required'),
        isError: true,
      );
      return;
    }

    if (_selectedDepartment == null || _selectedDepartment!.trim().isEmpty) {
      context.showSnackBar(
        context.tr('onboarding.department_required'),
        isError: true,
      );
      return;
    }

    ref.read(onboardingProvider.notifier).setStep2Data(
          jobTitle: _selectedJobTitle!,
          department: _selectedDepartment!,
        );

    context.push(AppRoutes.onboardingReview);
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
                    // Step 2 Header
                    OnboardingHeader(
                      currentStep: 2,
                      totalSteps: 3,
                      title: context.tr('onboarding.step2_title'),
                      subtitle: context.tr('onboarding.step2_subtitle'),
                      showBack: true,
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.onboardingPersonal);
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    // 1. Job Title Selection UI
                    SelectionField(
                      label: context.tr('onboarding.job_title'),
                      value: _selectedJobTitle,
                      placeholder: context.tr('onboarding.select_job_title'),
                      icon: Icons.work_outline_rounded,
                      hasError: _submitted && (_selectedJobTitle == null || _selectedJobTitle!.isEmpty),
                      onTap: _openJobTitlePicker,
                    ),
                    const SizedBox(height: 20),

                    // 2. Department Selection UI
                    SelectionField(
                      label: context.tr('onboarding.department'),
                      value: _selectedDepartment,
                      placeholder: context.tr('onboarding.select_department'),
                      icon: Icons.domain_rounded,
                      hasError: _submitted && (_selectedDepartment == null || _selectedDepartment!.isEmpty),
                      onTap: _openDepartmentPicker,
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
