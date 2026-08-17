import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/onboarding_provider.dart';

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

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingProvider);
    // Use onboarding state if set, otherwise fall back to auth employee
    // Only use employee values that are present in the catalog to avoid dropdown assertion errors
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
            : null);
    _selectedDepartment = formState.department.isNotEmpty
        ? formState.department
        : (empDept != null && catalog.departments.contains(empDept)
            ? empDept
            : null);
    _selectedRegion = formState.region.isNotEmpty
        ? formState.region
        : (empRegion != null && catalog.regions.contains(empRegion)
            ? empRegion
            : null);
    _selectedManagerId = formState.managerId.isNotEmpty
        ? formState.managerId
        : (empManagerId != null &&
                catalog.managers.any((m) => m.id == empManagerId)
            ? empManagerId
            : null);
  }

  void _handleNext() {
    if (_selectedJobTitle == null ||
        _selectedDepartment == null ||
        _selectedRegion == null ||
        _selectedManagerId == null) {
      context.showSnackBar('يرجى ملء جميع الحقول', isError: true);
      return;
    }

    final managerName = _getManagerName(_selectedManagerId!);

    ref
        .read(onboardingProvider.notifier)
        .setStep2Data(
          jobTitle: _selectedJobTitle!,
          department: _selectedDepartment!,
          region: _selectedRegion!,
          managerId: _selectedManagerId!,
          managerName: managerName,
        );

    context.push(AppRoutes.onboardingLocation);
  }

  String _getManagerName(String managerId) {
    final catalog = ref.read(onboardingCatalogProvider);
    final manager = catalog.managers.firstWhere(
      (m) => m.id == managerId,
      orElse: () => catalog.managers.first,
    );
    return manager.name;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catalog = ref.watch(onboardingCatalogProvider);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              Container(
                height: 4,
                width: MediaQuery.of(context).size.width * 0.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                localizations.onboardingStep2Title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.onboardingStep2Subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Job Title Dropdown
              Text(
                localizations.onboardingJobTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedJobTitle,
                hint: Text(localizations.onboardingJobTitle),
                items: catalog.jobTitles.map((title) {
                  return DropdownMenuItem(value: title, child: Text(title));
                }).toList(),
                onChanged: (value) => setState(() => _selectedJobTitle = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceVariantLight,
                  border: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Department Dropdown
              Text(
                localizations.onboardingDepartment,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                hint: Text(localizations.onboardingDepartment),
                items: catalog.departments.map((dept) {
                  return DropdownMenuItem(value: dept, child: Text(dept));
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedDepartment = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceVariantLight,
                  border: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Region Dropdown
              Text(
                localizations.onboardingRegion,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedRegion,
                hint: Text(localizations.onboardingRegion),
                items: catalog.regions.map((region) {
                  return DropdownMenuItem(value: region, child: Text(region));
                }).toList(),
                onChanged: (value) => setState(() => _selectedRegion = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceVariantLight,
                  border: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Manager Dropdown
              Text(
                localizations.onboardingManager,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedManagerId,
                hint: Text(localizations.onboardingManager),
                items: catalog.managers.map((manager) {
                  return DropdownMenuItem(
                    value: manager.id,
                    child: Text('${manager.name} (${manager.department})'),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedManagerId = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceVariantLight,
                  border: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusLarge,
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 32),

              // Navigation Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDimensions.borderRadiusLarge,
                          ),
                        ),
                        child: Text(
                          localizations.onboardingBack,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDimensions.borderRadiusLarge,
                          ),
                        ),
                        child: Text(
                          localizations.onboardingNext,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
