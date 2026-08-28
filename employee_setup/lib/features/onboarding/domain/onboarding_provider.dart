import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/mock/seeds/onboarding_catalog.dart';
import '../../../core/services/device_info_service.dart';
import '../../../core/utils/secure_logger.dart';

/// Notification permission grant status for audit & onboarding
enum NotificationPermissionStatus {
  authorized,
  denied,
  provisional,
  notDetermined;

  String get statusName => name.toUpperCase();
}

/// Token payload metadata prepared for real backend connection
class BackendPushTokenRegistration {
  final String deviceId;
  final String deviceType;
  final String? pushToken;
  final String appVersion;
  final String status; // 'BACKEND_PENDING'

  const BackendPushTokenRegistration({
    required this.deviceId,
    required this.deviceType,
    this.pushToken,
    required this.appVersion,
    this.status = 'BACKEND_PENDING',
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceType': deviceType,
        'pushToken': pushToken,
        'appVersion': appVersion,
        'status': status,
      };
}

/// Onboarding form state holding in-progress data across the 3-step MVP flow
class OnboardingFormState {
  // Step 1: Basic Information
  final String fullName;
  final String email;
  final String phone;

  // Step 2: Job & Department
  final String jobTitleId;
  final String jobTitle;
  final String departmentId;
  final String department;
  final EmployeeRole role;
  final HierarchyLevel hierarchyLevel;

  // Operational & Submission flags
  final bool isSubmitting;
  final String? errorMessage;
  final NotificationPermissionStatus notificationPermissionStatus;
  final DeviceInfo? capturedDeviceInfo;
  final BackendPushTokenRegistration? pushTokenRegistration;

  // Legacy fields preserved for backward compatibility
  final String nationalId;
  final String region;
  final String managerId;
  final String managerName;
  final String workLocationId;
  final bool biometricEnabled;

  const OnboardingFormState({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.jobTitleId = '',
    this.jobTitle = '',
    this.departmentId = '',
    this.department = '',
    this.role = EmployeeRole.employee,
    this.hierarchyLevel = HierarchyLevel.staff,
    this.isSubmitting = false,
    this.errorMessage,
    this.notificationPermissionStatus = NotificationPermissionStatus.notDetermined,
    this.capturedDeviceInfo,
    this.pushTokenRegistration,
    this.nationalId = '',
    this.region = '',
    this.managerId = '',
    this.managerName = '',
    this.workLocationId = '',
    this.biometricEnabled = false,
  });

  OnboardingFormState copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? jobTitleId,
    String? jobTitle,
    String? departmentId,
    String? department,
    EmployeeRole? role,
    HierarchyLevel? hierarchyLevel,
    bool? isSubmitting,
    String? errorMessage,
    NotificationPermissionStatus? notificationPermissionStatus,
    DeviceInfo? capturedDeviceInfo,
    BackendPushTokenRegistration? pushTokenRegistration,
    String? nationalId,
    String? region,
    String? managerId,
    String? managerName,
    String? workLocationId,
    bool? biometricEnabled,
  }) {
    return OnboardingFormState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      jobTitleId: jobTitleId ?? this.jobTitleId,
      jobTitle: jobTitle ?? this.jobTitle,
      departmentId: departmentId ?? this.departmentId,
      department: department ?? this.department,
      role: role ?? this.role,
      hierarchyLevel: hierarchyLevel ?? this.hierarchyLevel,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      notificationPermissionStatus:
          notificationPermissionStatus ?? this.notificationPermissionStatus,
      capturedDeviceInfo: capturedDeviceInfo ?? this.capturedDeviceInfo,
      pushTokenRegistration:
          pushTokenRegistration ?? this.pushTokenRegistration,
      nationalId: nationalId ?? this.nationalId,
      region: region ?? this.region,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      workLocationId: workLocationId ?? this.workLocationId,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}

/// Onboarding Notifier to manage form state across Step 1, Step 2, and Step 3
class OnboardingNotifier extends StateNotifier<OnboardingFormState> {
  final Ref ref;

  OnboardingNotifier(this.ref) : super(const OnboardingFormState());

  /// Initialize default fields from current authenticated user
  void initFromEmployee() {
    final currentEmployee = ref.read(authProvider).employee;
    if (currentEmployee != null) {
      state = state.copyWith(
        fullName: state.fullName.isNotEmpty
            ? state.fullName
            : (currentEmployee.googleName ?? currentEmployee.name),
        email: currentEmployee.googleEmail ?? currentEmployee.email,
        phone: state.phone.isNotEmpty ? state.phone : currentEmployee.phone,
        jobTitle: state.jobTitle.isNotEmpty
            ? state.jobTitle
            : (currentEmployee.jobTitle.isNotEmpty
                ? currentEmployee.jobTitle
                : ''),
        department: state.department.isNotEmpty
            ? state.department
            : (currentEmployee.department.isNotEmpty
                ? currentEmployee.department
                : ''),
      );
    }
  }

  /// Set Step 1 data (Basic Information)
  void setStep1Data({
    required String fullName,
    required String email,
    required String phone,
  }) {
    state = state.copyWith(
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      errorMessage: null,
    );
  }

  /// Set Step 2 data (Job & Department)
  void setStep2Data({
    required String jobTitle,
    required String department,
    String? jobTitleId,
    String? departmentId,
    EmployeeRole role = EmployeeRole.employee,
    HierarchyLevel hierarchyLevel = HierarchyLevel.staff,
    String? region,
    String? managerId,
    String? managerName,
  }) {
    final resolvedJob = OnboardingCatalog.findJobTitle(jobTitleId ?? jobTitle);
    final resolvedDept = OnboardingCatalog.findDepartment(departmentId ?? department);

    state = state.copyWith(
      jobTitleId: resolvedJob?.id ?? (jobTitleId ?? ''),
      jobTitle: jobTitle.trim(),
      departmentId: resolvedDept?.id ?? (departmentId ?? ''),
      department: department.trim(),
      role: role,
      hierarchyLevel: hierarchyLevel,
      region: region,
      managerId: managerId,
      managerName: managerName,
      errorMessage: null,
    );
  }

  /// Legacy Step 3 compatibility
  void setStep3Data({
    required String workLocationId,
    required bool biometricEnabled,
  }) {
    state = state.copyWith(
      workLocationId: workLocationId,
      biometricEnabled: biometricEnabled,
    );
  }

  /// Complete profile with idempotency, device metadata capture, and notification request
  Future<bool> completeProfile() async {
    // 1. Guard against double-taps / concurrent calls
    if (state.isSubmitting) {
      SecureLogger.info('OnboardingNotifier', 'Duplicate completeProfile submission ignored.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final currentEmployee = ref.read(authProvider).employee;

      if (currentEmployee == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'User not authenticated',
        );
        return false;
      }

      // 2. Request Notification Permission
      NotificationPermissionStatus notifStatus = NotificationPermissionStatus.notDetermined;
      try {
        final notifService = ref.read(notificationServiceProvider);
        final granted = await notifService.requestPermission();
        notifStatus = granted
            ? NotificationPermissionStatus.authorized
            : NotificationPermissionStatus.denied;
      } catch (e) {
        SecureLogger.warn('OnboardingNotifier', 'Notification permission request error: $e');
        notifStatus = NotificationPermissionStatus.denied;
      }

      // 3. Obtain Device Info
      DeviceInfo? devInfo;
      try {
        final deviceService = ref.read(deviceInfoServiceProvider);
        devInfo = await deviceService.getDeviceInfo();
      } catch (e) {
        SecureLogger.warn('OnboardingNotifier', 'Device info fetch error: $e');
      }

      // 4. Prepare Push Token Integration Payload (marked as BACKEND_PENDING)
      final pushRegistration = BackendPushTokenRegistration(
        deviceId: devInfo?.deviceId ?? 'DEVICE-FALLBACK-01',
        deviceType: devInfo?.deviceType.typeName ?? 'OTHER',
        appVersion: devInfo?.appVersion ?? '1.0.0+1',
        status: 'BACKEND_PENDING',
      );

      // 5. Construct completed employee record
      final updatedEmployee = currentEmployee.copyWith(
        name: state.fullName.isNotEmpty ? state.fullName : currentEmployee.name,
        email: currentEmployee.googleEmail ?? currentEmployee.email,
        phone: state.phone.isNotEmpty ? state.phone : currentEmployee.phone,
        jobTitle: state.jobTitle.isNotEmpty ? state.jobTitle : currentEmployee.jobTitle,
        department: state.department.isNotEmpty ? state.department : currentEmployee.department,
        onboardingCompleted: true,
        profileCompleted: true,
      );

      // 6. Update local storage persistence
      final localStorage = ref.read(localStorageProvider);
      await localStorage.setString(AppConstants.keyOnboardingCompleted, 'true');

      // 7. Update Auth state (triggers navigation to Home)
      await authNotifier.updateEmployee(updatedEmployee);

      state = state.copyWith(
        isSubmitting: false,
        notificationPermissionStatus: notifStatus,
        capturedDeviceInfo: devInfo,
        pushTokenRegistration: pushRegistration,
      );

      return true;
    } catch (e) {
      SecureLogger.error('OnboardingNotifier', 'Profile completion failed: $e', e);
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Complete onboarding alias for legacy compatibility
  Future<void> completeOnboarding() async {
    await completeProfile();
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
