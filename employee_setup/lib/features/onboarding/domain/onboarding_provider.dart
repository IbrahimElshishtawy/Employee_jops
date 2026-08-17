import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:employee_setup/features/auth/domain/models/employee.dart';
import 'package:employee_setup/features/auth/application/providers/auth_provider.dart';
import 'package:employee_setup/core/mock/seeds/onboarding_catalog.dart';
import 'package:employee_setup/core/constants/app_constants.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';

/// Onboarding form state holding in-progress data across 3 steps
class OnboardingFormState {
  // Step 1: Personal Information
  final String fullName;
  final String email;
  final String nationalId;
  final String phone;

  // Step 2: Work Information
  final String jobTitle;
  final String department;
  final String region;
  final String managerId;
  final String managerName;

  // Step 3: Location & Biometric
  final String workLocationId;
  final bool biometricEnabled;

  const OnboardingFormState({
    this.fullName = '',
    this.email = '',
    this.nationalId = '',
    this.phone = '',
    this.jobTitle = '',
    this.department = '',
    this.region = '',
    this.managerId = '',
    this.managerName = '',
    this.workLocationId = '',
    this.biometricEnabled = false,
  });

  OnboardingFormState copyWith({
    String? fullName,
    String? email,
    String? nationalId,
    String? phone,
    String? jobTitle,
    String? department,
    String? region,
    String? managerId,
    String? managerName,
    String? workLocationId,
    bool? biometricEnabled,
  }) {
    return OnboardingFormState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      nationalId: nationalId ?? this.nationalId,
      phone: phone ?? this.phone,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      region: region ?? this.region,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      workLocationId: workLocationId ?? this.workLocationId,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}

/// Onboarding Notifier to manage form state
class OnboardingNotifier extends StateNotifier<OnboardingFormState> {
  final Ref ref;

  OnboardingNotifier(this.ref) : super(const OnboardingFormState());

  /// Set Step 1 data (personal information)
  void setStep1Data({
    required String fullName,
    required String email,
    required String nationalId,
    required String phone,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      nationalId: nationalId,
      phone: phone,
    );
  }

  /// Set Step 2 data (work information)
  void setStep2Data({
    required String jobTitle,
    required String department,
    required String region,
    required String managerId,
    required String managerName,
  }) {
    state = state.copyWith(
      jobTitle: jobTitle,
      department: department,
      region: region,
      managerId: managerId,
      managerName: managerName,
    );
  }

  /// Set Step 3 data (location & biometric)
  void setStep3Data({
    required String workLocationId,
    required bool biometricEnabled,
  }) {
    state = state.copyWith(
      workLocationId: workLocationId,
      biometricEnabled: biometricEnabled,
    );
  }

  /// Complete onboarding and update employee in auth notifier
  Future<void> completeOnboarding() async {
    final authNotifier = ref.read(authProvider.notifier);
    final currentEmployee = ref.read(authProvider).employee;

    if (currentEmployee == null) return;

    // Create updated employee with onboarding completed flag
    final updatedEmployee = currentEmployee.copyWith(
      nationalId: state.nationalId,
      jobTitle: state.jobTitle,
      department: state.department,
      region: state.region,
      managerId: state.managerId,
      managerName: state.managerName,
      workLocationId: state.workLocationId,
      biometricEnabled: state.biometricEnabled,
      onboardingCompleted: true,
    );

    // Save to storage
    final localStorage = SharedPrefsStorage();
    await localStorage.init();
    await localStorage.setString(AppConstants.keyOnboardingCompleted, 'true');
    await localStorage.setString(
      AppConstants.keyBiometricEnabled,
      state.biometricEnabled.toString(),
    );

    // Update in auth notifier
    authNotifier.updateEmployee(updatedEmployee);

    // Reset form
    state = const OnboardingFormState();
  }
}

/// Onboarding form state provider
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingFormState>((ref) {
      return OnboardingNotifier(ref);
    });

/// Catalog data provider for dropdowns
final onboardingCatalogProvider = Provider((ref) {
  return OnboardingCatalogData(
    jobTitles: OnboardingCatalog.jobTitles,
    departments: OnboardingCatalog.departments,
    regions: OnboardingCatalog.regions,
    managers: OnboardingCatalog.managers,
    hrContact: OnboardingCatalog.hrContact,
  );
});

/// Onboarding catalog data class
class OnboardingCatalogData {
  final List<String> jobTitles;
  final List<String> departments;
  final List<String> regions;
  final List<ManagerInfo> managers;
  final HrContact hrContact;

  OnboardingCatalogData({
    required this.jobTitles,
    required this.departments,
    required this.regions,
    required this.managers,
    required this.hrContact,
  });
}
