import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/mock/seeds/onboarding_catalog.dart';
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
  String? _selectedJobTitleId;
  String? _selectedDepartmentId;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingProvider);
    final employee = ref.read(authProvider).employee;

    // Resolve initial Job Title
    if (formState.jobTitleId.isNotEmpty) {
      _selectedJobTitleId = formState.jobTitleId;
    } else if (formState.jobTitle.isNotEmpty) {
      _selectedJobTitleId = OnboardingCatalog.findJobTitle(formState.jobTitle)?.id ?? formState.jobTitle;
    } else if (employee != null && employee.jobTitle.isNotEmpty) {
      _selectedJobTitleId = OnboardingCatalog.findJobTitle(employee.jobTitle)?.id;
    }

    // Resolve initial Department
    if (formState.departmentId.isNotEmpty) {
      _selectedDepartmentId = formState.departmentId;
    } else if (formState.department.isNotEmpty) {
      _selectedDepartmentId = OnboardingCatalog.findDepartment(formState.department)?.id ?? formState.department;
    } else if (employee != null && employee.department.isNotEmpty) {
      _selectedDepartmentId = OnboardingCatalog.findDepartment(employee.department)?.id;
    }
  }

  void _openJobTitlePicker() async {
    final isArabic = context.isArabic;
    final items = OnboardingCatalog.jobTitleOptions
        .map((opt) => SelectionItem(
              id: opt.id,
              title: opt.localizedName(isArabic),
              subtitle: isArabic ? opt.nameEn : opt.nameAr,
              icon: Icons.badge_outlined,
            ))
        .toList();

    final result = await SelectionBottomSheet.show(
      context: context,
      title: context.tr('onboarding.select_job_title'),
      items: items,
      selectedId: _selectedJobTitleId,
    );

    if (result != null) {
      setState(() {
        _selectedJobTitleId = result.id;
      });
      _persistData();
    }
  }

  void _openDepartmentPicker() async {
    final isArabic = context.isArabic;
    final items = OnboardingCatalog.departmentOptions
        .map((opt) => SelectionItem(
              id: opt.id,
              title: opt.localizedName(isArabic),
              subtitle: isArabic ? opt.nameEn : opt.nameAr,
              emoji: opt.emoji,
            ))
        .toList();

    final result = await SelectionBottomSheet.show(
      context: context,
      title: context.tr('onboarding.select_department'),
      items: items,
      selectedId: _selectedDepartmentId,
    );

    if (result != null) {
      setState(() {
        _selectedDepartmentId = result.id;
      });
      _persistData();
    }
  }

  void _persistData() {
    final isArabic = context.isArabic;
    final jobOpt = OnboardingCatalog.findJobTitle(_selectedJobTitleId);
    final deptOpt = OnboardingCatalog.findDepartment(_selectedDepartmentId);

    ref.read(onboardingProvider.notifier).setStep2Data(
          jobTitleId: _selectedJobTitleId,
          jobTitle: jobOpt?.localizedName(isArabic) ?? (_selectedJobTitleId ?? ''),
          departmentId: _selectedDepartmentId,
          department: deptOpt?.localizedName(isArabic) ?? (_selectedDepartmentId ?? ''),
        );
  }

  void _handleContinue() {
    setState(() => _submitted = true);

    if (_selectedJobTitleId == null || _selectedJobTitleId!.trim().isEmpty) {
      context.showSnackBar(
        context.tr('onboarding.job_required'),
        isError: true,
      );
      return;
    }

    if (_selectedDepartmentId == null || _selectedDepartmentId!.trim().isEmpty) {
      context.showSnackBar(
        context.tr('onboarding.department_required'),
        isError: true,
      );
      return;
    }

    _persistData();
    context.push(AppRoutes.onboardingReview);
  }

  void _handleBack() {
    _persistData();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.onboardingPersonal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isArabic = context.isArabic;

    final jobOpt = OnboardingCatalog.findJobTitle(_selectedJobTitleId);
    final deptOpt = OnboardingCatalog.findDepartment(_selectedDepartmentId);

    final displayJobTitle = jobOpt?.localizedName(isArabic) ?? _selectedJobTitleId;
    final displayDepartment = deptOpt?.localizedName(isArabic) ?? _selectedDepartmentId;
    final departmentEmoji = deptOpt?.emoji;

    final isJobMissing = _submitted && (_selectedJobTitleId == null || _selectedJobTitleId!.isEmpty);
    final isDeptMissing = _submitted && (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty);

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
                      onBack: _handleBack,
                    ),
                    const SizedBox(height: 32),

                    // 1. Job Title Selection UI
                    SelectionField(
                      label: context.tr('onboarding.job_title'),
                      value: displayJobTitle,
                      placeholder: context.tr('onboarding.select_job_title'),
                      icon: Icons.work_outline_rounded,
                      hasError: isJobMissing,
                      errorText: isJobMissing ? context.tr('onboarding.job_required') : null,
                      onTap: _openJobTitlePicker,
                    ),
                    const SizedBox(height: 20),

                    // 2. Department Selection UI
                    SelectionField(
                      label: context.tr('onboarding.department'),
                      value: displayDepartment,
                      placeholder: context.tr('onboarding.select_department'),
                      icon: Icons.domain_rounded,
                      leadingEmoji: departmentEmoji,
                      hasError: isDeptMissing,
                      errorText: isDeptMissing ? context.tr('onboarding.department_required') : null,
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
