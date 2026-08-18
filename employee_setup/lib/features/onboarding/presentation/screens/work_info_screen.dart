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
  String? _selectedRegion;
  String? _selectedManagerId;
  String? _selectedManagerName;

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingProvider);
    final employee = ref.read(authProvider).employee;
    final catalog = ref.read(onboardingCatalogProvider);

    final empJobTitle = employee?.jobTitle;
    final empDept = employee?.department;
    final empRegion = employee?.region;
    final empManagerId = employee?.managerId;

    _selectedJobTitle = formState.jobTitle.isNotEmpty
        ? formState.jobTitle
        : (empJobTitle != null && catalog.jobTitles.contains(empJobTitle)
            ? empJobTitle
            : (catalog.jobTitles.isNotEmpty ? catalog.jobTitles.first : null));

    _selectedDepartment = formState.department.isNotEmpty
        ? formState.department
        : (empDept != null && catalog.departments.contains(empDept)
            ? empDept
            : (catalog.departments.isNotEmpty ? catalog.departments.first : null));

    _selectedRegion = formState.region.isNotEmpty
        ? formState.region
        : (empRegion != null && catalog.regions.contains(empRegion)
            ? empRegion
            : (catalog.regions.isNotEmpty ? catalog.regions.first : null));

    _selectedManagerId = formState.managerId.isNotEmpty
        ? formState.managerId
        : (empManagerId != null &&
                catalog.managers.any((m) => m.id == empManagerId)
            ? empManagerId
            : (catalog.managers.isNotEmpty ? catalog.managers.first.id : null));

    _selectedManagerName = formState.managerName.isNotEmpty
        ? formState.managerName
        : (catalog.managers.isNotEmpty ? catalog.managers.first.name : null);
  }

  void _openJobTitlePicker() async {
    final catalog = ref.read(onboardingCatalogProvider);
    final items = catalog.jobTitles
        .map((t) => SelectionItem(id: t, title: t, icon: Icons.work_outline_rounded))
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
        .map((d) => SelectionItem(id: d, title: d, icon: Icons.domain_rounded))
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

  void _openRegionPicker() async {
    final catalog = ref.read(onboardingCatalogProvider);
    final items = catalog.regions
        .map((r) => SelectionItem(id: r, title: r, icon: Icons.location_city_rounded))
        .toList();

    final result = await SelectionBottomSheet.show(
      context: context,
      title: context.tr('onboarding.select_region'),
      items: items,
      selectedId: _selectedRegion,
    );

    if (result != null) {
      setState(() => _selectedRegion = result.id);
    }
  }

  void _openManagerPicker() async {
    final catalog = ref.read(onboardingCatalogProvider);
    final items = catalog.managers
        .map((m) => SelectionItem(
              id: m.id,
              title: m.name,
              subtitle: m.department,
              icon: Icons.person_outline_rounded,
            ))
        .toList();

    final result = await SelectionBottomSheet.show(
      context: context,
      title: context.tr('onboarding.select_manager'),
      items: items,
      selectedId: _selectedManagerId,
    );

    if (result != null) {
      setState(() {
        _selectedManagerId = result.id;
        _selectedManagerName = result.title;
      });
    }
  }

  void _handleContinue() {
    setState(() => _submitted = true);

    if (_selectedJobTitle == null ||
        _selectedDepartment == null ||
        _selectedRegion == null ||
        _selectedManagerId == null) {
      context.showSnackBar(
        context.tr('onboarding.required_fields_error'),
        isError: true,
      );
      return;
    }

    final catalog = ref.read(onboardingCatalogProvider);
    final managerName = _selectedManagerName ??
        catalog.managers
            .firstWhere(
              (m) => m.id == _selectedManagerId,
              orElse: () => catalog.managers.first,
            )
            .name;

    ref.read(onboardingProvider.notifier).setStep2Data(
          jobTitle: _selectedJobTitle!,
          department: _selectedDepartment!,
          region: _selectedRegion!,
          managerId: _selectedManagerId!,
          managerName: managerName,
        );

    context.push(AppRoutes.onboardingLocation);
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
                      currentStep: 2,
                      totalSteps: 3,
                      title: context.tr('onboarding.step2_title'),
                      subtitle: context.tr('onboarding.step2_subtitle'),
                      showBack: true,
                      onBack: () => context.pop(),
                    ),
                    const SizedBox(height: 32),

                    // 1. Job Title Selection
                    SelectionField(
                      label: context.tr('onboarding.job_title'),
                      value: _selectedJobTitle,
                      placeholder: context.tr('onboarding.select_job_title'),
                      icon: Icons.work_outline_rounded,
                      hasError: _submitted && _selectedJobTitle == null,
                      onTap: _openJobTitlePicker,
                    ),
                    const SizedBox(height: 18),

                    // 2. Department Selection
                    SelectionField(
                      label: context.tr('onboarding.department'),
                      value: _selectedDepartment,
                      placeholder: context.tr('onboarding.select_department'),
                      icon: Icons.domain_rounded,
                      hasError: _submitted && _selectedDepartment == null,
                      onTap: _openDepartmentPicker,
                    ),
                    const SizedBox(height: 18),

                    // 3. Region Selection
                    SelectionField(
                      label: context.tr('onboarding.region'),
                      value: _selectedRegion,
                      placeholder: context.tr('onboarding.select_region'),
                      icon: Icons.location_city_rounded,
                      hasError: _submitted && _selectedRegion == null,
                      onTap: _openRegionPicker,
                    ),
                    const SizedBox(height: 18),

                    // 4. Direct Manager Selection
                    SelectionField(
                      label: context.tr('onboarding.manager'),
                      value: _selectedManagerName,
                      placeholder: context.tr('onboarding.select_manager'),
                      icon: Icons.person_pin_circle_outlined,
                      hasError: _submitted && _selectedManagerId == null,
                      onTap: _openManagerPicker,
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
