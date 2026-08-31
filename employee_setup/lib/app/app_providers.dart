import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/mock/mock_database.dart';
import '../core/mock/models/app_session.dart';
import '../core/mock/models/deduction.dart';
import '../core/mock/models/hr_message.dart';
import '../core/mock/repositories/deduction_repository.dart';
import '../core/mock/repositories/hr_message_repository.dart';
import '../core/mock/repositories/mock_deduction_repository.dart';
import '../core/mock/repositories/mock_hr_message_repository.dart';
import '../core/network/connectivity_service.dart';
import '../core/network/mock_connectivity_service.dart';
import '../core/storage/local_storage.dart';

import '../core/services/time_service.dart';
import '../features/advances/data/repositories/mock_advances_repository.dart';
import '../features/advances/domain/models/advance_request.dart';
import '../features/advances/domain/repositories/advances_repository.dart';

import '../features/attendance/data/api/attendance_api.dart';
import '../features/attendance/data/api/mock_attendance_api.dart';
import '../features/attendance/data/repositories/mock_attendance_repository.dart';
import '../features/attendance/data/services/device_integrity_service_impl.dart';
import '../features/attendance/data/services/mock_biometric_service.dart';
import '../features/attendance/data/services/mock_location_detector_impl.dart';
import '../features/attendance/data/services/mock_location_service.dart';
import '../features/attendance/data/services/network_risk_service_impl.dart';
import '../features/attendance/data/services/screen_overlay_detector_impl.dart';
import '../features/attendance/domain/models/attendance.dart';
import '../features/attendance/domain/models/attendance_api_contracts.dart';
import '../features/attendance/domain/models/attendance_state_type.dart';
import '../features/attendance/domain/models/device_integrity_result.dart';
import '../features/attendance/domain/models/location_result.dart';
import '../features/attendance/domain/models/network_risk_info.dart';
import '../features/attendance/domain/models/work_schedule.dart';
import '../features/attendance/domain/models/attendance_verification_result.dart';
import '../features/attendance/domain/services/attendance_security_orchestrator.dart';
import '../features/attendance/domain/services/attendance_audit_service.dart';
import '../features/attendance/domain/services/attendance_policy_service.dart';
import '../features/attendance/domain/services/attendance_verification_service.dart';
import '../features/attendance/domain/services/biometric_service.dart';
import '../features/attendance/domain/services/device_integrity_service.dart';
import '../features/attendance/domain/services/geofence_service.dart';
import '../features/attendance/domain/services/location_service.dart';
import '../features/attendance/domain/services/mock_location_detector.dart';
import '../features/attendance/domain/services/network_risk_service.dart';
import '../features/attendance/domain/services/screen_overlay_detector.dart';
import '../features/attendance/domain/services/work_schedule_service.dart';

import '../features/auth/data/datasources/mock_auth_datasource.dart';
import '../features/auth/domain/models/employee.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

import '../features/notifications/data/repositories/mock_notifications_repository.dart';
import '../features/notifications/domain/models/app_notification.dart';
import '../features/notifications/domain/repositories/notifications_repository.dart';

import '../features/permissions/data/repositories/mock_permissions_repository.dart';
import '../features/permissions/domain/models/permission_request.dart';
import '../features/permissions/domain/repositories/permissions_repository.dart';

import '../features/requests/domain/models/unified_request.dart';
import '../features/requests/domain/repositories/requests_repository.dart';

import '../features/settings/domain/models/app_settings.dart';
import '../features/settings/domain/models/demo_controls.dart';
import '../features/vacations/data/repositories/mock_vacations_repository.dart';
import '../features/vacations/domain/models/vacation_request.dart';
import '../features/vacations/domain/repositories/vacations_repository.dart';

import '../core/storage/secure_session_storage.dart';
import '../core/services/notification_service.dart';
import '../core/services/device_info_service.dart';
import '../features/attendance/data/services/real_biometric_service.dart';
import '../features/attendance/data/services/real_location_service.dart';
import '../features/attendance/data/services/real_network_risk_service.dart';
import '../features/auth/data/datasources/real_auth_datasource.dart';
import '../features/auth/data/repositories/real_auth_repository.dart';
import '../features/location_tracking/presentation/providers/location_tracking_provider.dart';

// ══════════════════════════════════════════════════════════════════
// 0. MockDatabase Provider  (Single Source of Truth)
// ══════════════════════════════════════════════════════════════════
// Re-exported so screens can import from one place
export '../core/mock/mock_database.dart' show mockDatabaseProvider;
export '../features/location_tracking/presentation/providers/location_tracking_provider.dart'
    show locationTrackingProvider, locationTrackingRepositoryProvider, LocationTrackingState;

// ══════════════════════════════════════════════════════════════════
// 1. Core Infrastructure Providers
// ══════════════════════════════════════════════════════════════════

final localStorageProvider = Provider<LocalStorage>((ref) {
  return SecureSessionStorage();
});

final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return PlatformDeviceInfoService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.initialize();
  return service;
});

final timeServiceProvider = Provider<TimeService>((ref) {
  return DeviceTimeService();
});

final workScheduleServiceProvider = Provider<WorkScheduleService>((ref) {
  final timeService = ref.watch(timeServiceProvider);
  return WorkScheduleService(timeService);
});

final mockConnectivityServiceProvider = Provider<MockConnectivityService>((
  ref,
) {
  final service = MockConnectivityService(initialConnected: true);
  ref.onDispose(() => service.dispose());
  return service;
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ref.watch(mockConnectivityServiceProvider);
});

// ══════════════════════════════════════════════════════════════════
// 2. Demo Controls
// ══════════════════════════════════════════════════════════════════

class DemoControlsNotifier extends StateNotifier<DemoControlsState> {
  final Ref _ref;

  DemoControlsNotifier(this._ref) : super(const DemoControlsState());

  void setUseRealDeviceSensors(bool useReal) {
    state = state.copyWith(useRealDeviceSensors: useReal);
  }

  void setLocationMode(MockLocationMode mode, [double? distance]) {
    state = state.copyWith(
      useRealDeviceSensors: false,
      locationMode: mode,
      simulatedDistance:
          distance ?? (mode == MockLocationMode.insideRange ? 2.3 : 48.5),
    );
    final locService = _ref.read(mockLocationServiceProvider);
    locService.mode = mode;
    locService.customDistance = state.simulatedDistance;
    final mockDetector = _ref.read(mockLocationDetectorProvider) as MockLocationDetectorImpl;
    mockDetector.simulatedMockDetected = (mode == MockLocationMode.mockLocationDetected);
  }

  void setBiometricMode(MockBiometricMode mode) {
    state = state.copyWith(
      useRealDeviceSensors: false,
      biometricMode: mode,
    );
    final bioService = _ref.read(mockBiometricServiceProvider);
    bioService.mode = mode;
  }

  void setNetworkOnline(bool online) {
    state = state.copyWith(isOnline: online);
    final connService = _ref.read(mockConnectivityServiceProvider);
    connService.setConnected(online);
  }

  Future<void> resetAllData() async {
    // Reset all data but keep the current session
    _ref.read(mockDatabaseProvider.notifier).resetDataKeepSession();

    state = const DemoControlsState();
    final locService = _ref.read(mockLocationServiceProvider);
    locService.mode = MockLocationMode.insideRange;
    locService.customDistance = 2.3;

    final bioService = _ref.read(mockBiometricServiceProvider);
    bioService.mode = MockBiometricMode.alwaysSuccess;

    setNetworkOnline(true);

    // Invalidate all derived providers
    _ref.invalidate(attendanceSummaryProvider);
    _ref.invalidate(attendanceHistoryProvider);
    _ref.invalidate(advancesListProvider);
    _ref.invalidate(permissionsListProvider);
    _ref.invalidate(vacationsListProvider);
    _ref.invalidate(allRequestsProvider);
    _ref.invalidate(notificationsListProvider);
    _ref.invalidate(unreadNotificationsCountProvider);
  }
}

final demoControlsProvider =
    StateNotifierProvider<DemoControlsNotifier, DemoControlsState>((ref) {
      return DemoControlsNotifier(ref);
    });

// ══════════════════════════════════════════════════════════════════
// 3. Location, Biometric & Security Services
// ══════════════════════════════════════════════════════════════════

final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  return const GeofenceService();
});

final attendancePolicyServiceProvider = Provider<AttendancePolicyService>((ref) {
  return const AttendancePolicyService();
});

final mockLocationDetectorProvider = Provider<MockLocationDetector>((ref) {
  return MockLocationDetectorImpl();
});

final deviceIntegrityServiceProvider = Provider<DeviceIntegrityService>((ref) {
  return DeviceIntegrityServiceImpl();
});

final realNetworkRiskServiceProvider = Provider<RealNetworkRiskService>((ref) {
  return RealNetworkRiskService();
});

final networkRiskServiceProvider = Provider<NetworkRiskService>((ref) {
  final demo = ref.watch(demoControlsProvider);
  if (!demo.useRealDeviceSensors) {
    return NetworkRiskServiceImpl();
  }
  return ref.watch(realNetworkRiskServiceProvider);
});

final attendanceAuditServiceProvider = Provider<AttendanceAuditService>((ref) {
  return AttendanceAuditService();
});

final mockLocationServiceProvider = Provider<MockLocationService>((ref) {
  final emp = ref.watch(employeeProvider);
  return MockLocationService(
    workplaceLatitude: emp.workplaceLatitude ?? AppConstants.officeLatitude,
    workplaceLongitude: emp.workplaceLongitude ?? AppConstants.officeLongitude,
  );
});

final realLocationServiceProvider = Provider<RealLocationService>((ref) {
  final emp = ref.watch(employeeProvider);
  return RealLocationService(
    workplaceLatitude: emp.workplaceLatitude ?? AppConstants.officeLatitude,
    workplaceLongitude: emp.workplaceLongitude ?? AppConstants.officeLongitude,
    allowedRadiusMeters: emp.allowedRadiusMeters > 0
        ? emp.allowedRadiusMeters
        : AttendancePolicyService.defaultAllowedRadiusMeters,
  );
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final demo = ref.watch(demoControlsProvider);
  if (!demo.useRealDeviceSensors) {
    return ref.watch(mockLocationServiceProvider);
  }
  return ref.watch(realLocationServiceProvider);
});

final mockBiometricServiceProvider = Provider<MockBiometricService>((ref) {
  return MockBiometricService();
});

final realBiometricServiceProvider = Provider<RealBiometricService>((ref) {
  return RealBiometricService();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  final demo = ref.watch(demoControlsProvider);
  if (!demo.useRealDeviceSensors) {
    return ref.watch(mockBiometricServiceProvider);
  }
  return ref.watch(realBiometricServiceProvider);
});

final attendanceApiProvider = Provider<AttendanceApi>((ref) {
  return MockAttendanceApi(getEmployee: () => ref.watch(employeeProvider));
});

final screenOverlayDetectorProvider = Provider<ScreenOverlayDetector>((ref) {
  return ScreenOverlayDetectorImpl();
});

final attendanceVerificationServiceProvider =
    Provider<AttendanceVerificationService>((ref) {
      return AttendanceVerificationService(
        locationService: ref.watch(locationServiceProvider),
        geofenceService: ref.watch(geofenceServiceProvider),
        mockLocationDetector: ref.watch(mockLocationDetectorProvider),
        screenOverlayDetector: ref.watch(screenOverlayDetectorProvider),
        biometricService: ref.watch(biometricServiceProvider),
        deviceIntegrityService: ref.watch(deviceIntegrityServiceProvider),
        networkRiskService: ref.watch(networkRiskServiceProvider),
        workScheduleService: ref.watch(workScheduleServiceProvider),
        policyService: ref.watch(attendancePolicyServiceProvider),
      );
    });

// ══════════════════════════════════════════════════════════════════
// 4. Auth & Employee Providers
// ══════════════════════════════════════════════════════════════════

final authDataSourceProvider = Provider<MockAuthDataSource>((ref) {
  final storage = ref.watch(localStorageProvider);
  return MockAuthDataSource(storage);
});

final realAuthDataSourceProvider = Provider<RealAuthDataSource>((ref) {
  final storage = ref.watch(localStorageProvider);
  return RealAuthDataSource(storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final ds = ref.watch(realAuthDataSourceProvider);
  return RealAuthRepository(ds, ref);
});

/// The current authenticated Employee — derived from MockDatabase.
/// This is the primary source for all screens that need employee info.
final employeeProvider = Provider<Employee>((ref) {
  return ref.watch(mockDatabaseProvider).employee;
});

/// The current AppSession — null if logged out.
final sessionProvider = Provider<AppSession?>((ref) {
  return ref.watch(mockDatabaseProvider).session;
});

// AuthState — tracks authentication flow (loading, error, user)
class AuthState {
  final Employee? employee;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.employee,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => employee != null;

  AuthState copyWith({
    Employee? employee,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
  }) {
    return AuthState(
      employee: clearUser ? null : (employee ?? this.employee),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final user = await _repo.getCurrentUser();
    state = state.copyWith(employee: user, isInitialized: true);
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.signInWithGoogle();
      state = state.copyWith(employee: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      final trackingRepo = _ref.read(locationTrackingRepositoryProvider);
      await trackingRepo.stopTracking(reason: 'User signed out');
    } catch (_) {}

    await _repo.signOut();
    state = state.copyWith(clearUser: true);
  }

  /// Update employee profile (for onboarding completion)
  Future<void> updateEmployee(Employee updatedEmployee) async {
    await _repo.updateEmployee(updatedEmployee);
    state = state.copyWith(employee: updatedEmployee);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo, ref);
});

/// Convenience alias — nullable employee from auth state.
final currentEmployeeProvider = Provider<Employee?>((ref) {
  return ref.watch(authProvider).employee;
});

// ══════════════════════════════════════════════════════════════════
// 5. Attendance Providers — all derived from MockDatabase
// ══════════════════════════════════════════════════════════════════

/// The current employee's assigned work schedule
final workScheduleProvider = Provider<WorkSchedule>((ref) {
  return ref.watch(mockDatabaseProvider).workSchedule;
});

/// Current live evaluation of the employee's work schedule
final workScheduleShiftStatusProvider = Provider<WorkScheduleShiftStatus>((ref) {
  final scheduleService = ref.watch(workScheduleServiceProvider);
  final schedule = ref.watch(workScheduleProvider);
  return scheduleService.evaluateScheduleStatus(schedule);
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final api = ref.watch(attendanceApiProvider);
  return MockAttendanceRepository(ref, api);
});

/// Today's check-in / check-out summary — auto-updates when MockDatabase changes.
final attendanceSecurityOrchestratorProvider =
    Provider<AttendanceSecurityVerificationOrchestrator>((ref) {
  return AttendanceSecurityVerificationOrchestrator(
    locationService: ref.watch(locationServiceProvider),
    geofenceService: ref.watch(geofenceServiceProvider),
    mockLocationDetector: ref.watch(mockLocationDetectorProvider),
    screenOverlayDetector: ref.watch(screenOverlayDetectorProvider),
    biometricService: ref.watch(biometricServiceProvider),
    deviceIntegrityService: ref.watch(deviceIntegrityServiceProvider),
    networkRiskService: ref.watch(networkRiskServiceProvider),
    workScheduleService: ref.watch(workScheduleServiceProvider),
    policyService: ref.watch(attendancePolicyServiceProvider),
    authRepository: ref.watch(authRepositoryProvider),
    attendanceRepository: ref.watch(attendanceRepositoryProvider),
    auditService: ref.watch(attendanceAuditServiceProvider),
  );
});

final attendanceSummaryProvider = Provider<TodayAttendanceSummary>((ref) {
  return ref.watch(mockDatabaseProvider).todaySummary;
});

/// Full attendance history — sorted descending by timestamp.
final attendanceHistoryProvider = Provider<List<Attendance>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.attendance.where((a) => a.employeeId == empId).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

// ─── Attendance Action State ──────────────────────────────────────

enum AttendanceProcessState {
  idle,
  checkingLocation,
  authenticatingBiometric,
  submitting,
  success,
  error,
}

class AttendanceFlowState {
  final AttendanceProcessState processState;
  final AttendanceStateType stateType;
  final AttendanceSecurityVerificationResult? verificationResult;
  final LocationResult? locationResult;
  final DeviceIntegrityResult? integrityResult;
  final NetworkRiskInfo? networkRisk;
  final AttendanceVerificationResponse? lastResponse;
  final String? message;
  final bool isOffline;
  final bool isLocationUpdating;
  final bool isSyncing;
  final DateTime? lastLocationUpdateTime;

  const AttendanceFlowState({
    this.processState = AttendanceProcessState.idle,
    this.stateType = AttendanceStateType.notStarted,
    this.verificationResult,
    this.locationResult,
    this.integrityResult,
    this.networkRisk,
    this.lastResponse,
    this.message,
    this.isOffline = false,
    this.isLocationUpdating = false,
    this.isSyncing = false,
    this.lastLocationUpdateTime,
  });

  bool get isLoading =>
      processState == AttendanceProcessState.checkingLocation ||
      processState == AttendanceProcessState.authenticatingBiometric ||
      processState == AttendanceProcessState.submitting;

  GeofenceVerificationStatus get geofenceStatus =>
      verificationResult?.geofenceStatus ?? GeofenceVerificationStatus.idle;

  ScreenSecurityStatus get screenSecurityStatus =>
      verificationResult?.screenSecurityStatus ?? ScreenSecurityStatus.idle;

  BiometricVerificationStatus get biometricStatus =>
      verificationResult?.biometricStatus ?? BiometricVerificationStatus.idle;

  CloudAuthenticationStatus get cloudAuthenticationStatus =>
      verificationResult?.cloudAuthenticationStatus ?? CloudAuthenticationStatus.idle;

  CloudAttendanceRegistrationStatus get attendanceRegistrationStatus =>
      verificationResult?.attendanceRegistrationStatus ?? CloudAttendanceRegistrationStatus.idle;

  AttendanceFlowState copyWith({
    AttendanceProcessState? processState,
    AttendanceStateType? stateType,
    AttendanceSecurityVerificationResult? verificationResult,
    LocationResult? locationResult,
    DeviceIntegrityResult? integrityResult,
    NetworkRiskInfo? networkRisk,
    AttendanceVerificationResponse? lastResponse,
    String? message,
    bool? isOffline,
    bool? isLocationUpdating,
    bool? isSyncing,
    DateTime? lastLocationUpdateTime,
  }) {
    return AttendanceFlowState(
      processState: processState ?? this.processState,
      stateType: stateType ?? this.stateType,
      verificationResult: verificationResult ?? this.verificationResult,
      locationResult: locationResult ?? this.locationResult,
      integrityResult: integrityResult ?? this.integrityResult,
      networkRisk: networkRisk ?? this.networkRisk,
      lastResponse: lastResponse ?? this.lastResponse,
      message: message,
      isOffline: isOffline ?? this.isOffline,
      isLocationUpdating: isLocationUpdating ?? this.isLocationUpdating,
      isSyncing: isSyncing ?? this.isSyncing,
      lastLocationUpdateTime:
          lastLocationUpdateTime ?? this.lastLocationUpdateTime,
    );
  }
}

class AttendanceFlowNotifier extends StateNotifier<AttendanceFlowState> {
  final Ref _ref;

  AttendanceFlowNotifier(this._ref) : super(const AttendanceFlowState()) {
    // Initial silent location query
    refreshLocation();
  }

  /// Refreshes current GPS position and distance without triggering attendance submission.
  Future<LocationResult> refreshLocation() async {
    if (state.isLocationUpdating) {
      return state.locationResult ??
          LocationResult(
            latitude: 0,
            longitude: 0,
            distanceFromOfficeMeters: 9999,
            timestamp: DateTime(2000),
            status: LocationStatus.error,
          );
    }

    state = state.copyWith(isLocationUpdating: true);
    try {
      final employee = _ref.read(employeeProvider);
      final locationService = _ref.read(locationServiceProvider);
      final geofenceService = _ref.read(geofenceServiceProvider);

      final result = await locationService.getCurrentLocation();
      final wpLat = employee.workplaceLatitude ?? AppConstants.officeLatitude;
      final wpLon = employee.workplaceLongitude ?? AppConstants.officeLongitude;
      final distance = geofenceService.calculateDistanceInMeters(
        startLatitude: result.latitude,
        startLongitude: result.longitude,
        endLatitude: wpLat,
        endLongitude: wpLon,
      );

      final updatedResult = result.copyWith(distanceFromOfficeMeters: distance);
      state = state.copyWith(
        locationResult: updatedResult,
        isLocationUpdating: false,
        lastLocationUpdateTime: DateTime.now(),
      );
      return updatedResult;
    } catch (e) {
      state = state.copyWith(
        isLocationUpdating: false,
        message: 'تعذر تحديد الموقع الجغرافي حاليًا',
      );
      return LocationResult(
        latitude: 0,
        longitude: 0,
        distanceFromOfficeMeters: 9999,
        timestamp: DateTime.now(),
        status: LocationStatus.error,
      );
    }
  }

  /// Requests location permission from the device
  Future<bool> requestLocationPermission() async {
    final locationService = _ref.read(locationServiceProvider);
    final granted = await locationService.requestPermission();
    if (granted) {
      await refreshLocation();
    }
    return granted;
  }

  Future<bool> executeCheckIn() async {
    return _executeAttendanceAction(isCheckIn: true);
  }

  Future<bool> executeCheckOut() async {
    return _executeAttendanceAction(isCheckIn: false);
  }

  Future<bool> _executeAttendanceAction({required bool isCheckIn}) async {
    // Race Condition Prevention: ignore multiple rapid taps
    if (state.isLoading) return false;

    final orchestrator = _ref.read(attendanceSecurityOrchestratorProvider);
    final connectivity = _ref.read(connectivityServiceProvider);
    final notifRepo = _ref.read(notificationsRepositoryProvider);
    final db = _ref.read(mockDatabaseProvider);
    final employee = db.employee;
    final summary = db.todaySummary;
    final workSchedule = db.workSchedule;
    final session = db.session;
    final isOnline = await connectivity.isConnected;

    state = state.copyWith(
      processState: AttendanceProcessState.checkingLocation,
      stateType: AttendanceStateType.verifyingLocation,
      message: 'جاري التحقق من جلسة الموظف وأمان الجهاز...',
      isOffline: !isOnline,
    );

    final verificationResult = await orchestrator.executeVerification(
      employee: employee,
      workSchedule: workSchedule,
      todaySummary: summary,
      session: session,
      isCheckIn: isCheckIn,
      isOnline: isOnline,
      onStepUpdate: (stepResult) {
        AttendanceProcessState pState = state.processState;
        AttendanceStateType sType = state.stateType;

        if (stepResult.attendanceRegistrationStatus.isInProgress) {
          pState = AttendanceProcessState.submitting;
          sType = AttendanceStateType.submitting;
        } else if (stepResult.biometricStatus.isInProgress) {
          pState = AttendanceProcessState.authenticatingBiometric;
          sType = AttendanceStateType.verifyingBiometric;
        } else if (stepResult.geofenceStatus.isInProgress ||
            stepResult.screenSecurityStatus.isInProgress ||
            stepResult.cloudAuthenticationStatus.isInProgress) {
          pState = AttendanceProcessState.checkingLocation;
          sType = AttendanceStateType.verifyingLocation;
        }

        state = state.copyWith(
          processState: pState,
          stateType: sType,
          verificationResult: stepResult,
          locationResult: stepResult.locationResult ?? state.locationResult,
          integrityResult: stepResult.integrityResult ?? state.integrityResult,
          networkRisk: stepResult.networkRisk ?? state.networkRisk,
          lastResponse: stepResult.response ?? state.lastResponse,
          message: stepResult.errorMessage ?? state.message,
        );
      },
    );

    state = state.copyWith(
      verificationResult: verificationResult,
      locationResult: verificationResult.locationResult ?? state.locationResult,
      integrityResult: verificationResult.integrityResult ?? state.integrityResult,
      networkRisk: verificationResult.networkRisk ?? state.networkRisk,
      lastResponse: verificationResult.response ?? state.lastResponse,
      lastLocationUpdateTime: DateTime.now(),
    );

    // Handle failure
    if (verificationResult.isFailed || !verificationResult.isAllLocalChecksSuccessful) {
      AttendanceStateType failState = AttendanceStateType.error;
      if (verificationResult.geofenceStatus == GeofenceVerificationStatus.locationPermissionDenied) {
        failState = AttendanceStateType.locationPermissionDenied;
      } else if (verificationResult.geofenceStatus == GeofenceVerificationStatus.locationServiceDisabled) {
        failState = AttendanceStateType.locationServiceDisabled;
      } else if (verificationResult.geofenceStatus == GeofenceVerificationStatus.lowLocationAccuracy) {
        failState = AttendanceStateType.lowLocationAccuracy;
      } else if (verificationResult.geofenceStatus == GeofenceVerificationStatus.outsideGeofence) {
        failState = AttendanceStateType.outsideWorkplace;
      } else if (verificationResult.geofenceStatus == GeofenceVerificationStatus.mockLocationDetected) {
        failState = AttendanceStateType.mockLocationDetected;
      } else if (verificationResult.screenSecurityStatus.isFailed) {
        failState = AttendanceStateType.deviceIntegrityFailed;
      } else if (verificationResult.biometricStatus == BiometricVerificationStatus.biometricUnavailable ||
          verificationResult.biometricStatus == BiometricVerificationStatus.biometricNotAvailable) {
        failState = AttendanceStateType.biometricUnavailable;
      } else if (verificationResult.biometricStatus.isFailed) {
        failState = AttendanceStateType.biometricFailed;
      } else if (verificationResult.cloudAuthenticationStatus.isFailed) {
        failState = AttendanceStateType.error;
      } else if (verificationResult.attendanceRegistrationStatus.isFailed) {
        failState = AttendanceStateType.serverRejected;
      }

      state = state.copyWith(
        processState: AttendanceProcessState.error,
        stateType: failState,
        message: verificationResult.errorMessage ?? 'تعذر إتمام عملية التحقق والتسجيل.',
      );
      return false;
    }

    final response = verificationResult.response;
    if (response == null) {
      state = state.copyWith(
        processState: AttendanceProcessState.error,
        stateType: AttendanceStateType.error,
        message: verificationResult.errorMessage ?? 'لم يتم استلام استجابة من الخادم.',
      );
      return false;
    }

    final clientRequestId = response.attendanceRecord?.clientRequestId ??
        'REQ-${DateTime.now().millisecondsSinceEpoch}-${employee.id.hashCode}';

    // Work Session Location Tracking Integration
    if (response.isApproved || response.isPendingHr) {
      try {
        final trackingNotifier = _ref.read(locationTrackingProvider.notifier);
        if (isCheckIn) {
          await trackingNotifier.startWorkSessionTracking(
            workSessionId: clientRequestId,
            employeeId: employee.id,
          );
          if (db.session != null) {
            _ref.read(mockDatabaseProvider.notifier).setSession(
              db.session!.copyWith(
                workSessionStatus: 'active',
                workSessionId: clientRequestId,
                trackingActive: true,
              ),
            );
          }
        } else {
          await trackingNotifier.stopWorkSessionTracking(
            reason: 'Work session check-out completed',
          );
          if (db.session != null) {
            _ref.read(mockDatabaseProvider.notifier).setSession(
              db.session!.copyWith(
                workSessionStatus: 'inactive',
                trackingActive: false,
              ),
            );
          }
        }
      } catch (e) {
        // Location tracking error should not fail attendance submission
      }
    }

    if (response.isApproved) {
      final loc = verificationResult.locationResult;
      final distanceStr = loc != null ? ' (${loc.distanceFromOfficeMeters.toStringAsFixed(1)} م)' : '';
      await notifRepo.addNotification(
        AppNotification(
          id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
          title: isCheckIn ? 'تسجيل الحضور' : 'تسجيل الانصراف',
          message: 'تم ${isCheckIn ? 'تسجيل الحضور' : 'تسجيل الانصراف'} بنجاح$distanceStr',
          category: NotificationCategory.attendance,
          createdAt: DateTime.now(),
          isRead: false,
        ),
      );

      state = state.copyWith(
        processState: AttendanceProcessState.success,
        stateType: isCheckIn ? AttendanceStateType.checkedIn : AttendanceStateType.checkedOut,
        message: response.message ??
            (isCheckIn ? 'تم تسجيل الحضور بنجاح!' : 'تم تسجيل الانصراف بنجاح!'),
      );
      return true;
    } else if (response.isPendingHr) {
      await notifRepo.addNotification(
        AppNotification(
          id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
          title: isCheckIn ? 'تسجيل الحضور (بدون اتصال)' : 'تسجيل الانصراف (بدون اتصال)',
          message: 'تم الحفظ محلياً — في انتظار مراجعة الـ HR والمزامنة',
          category: NotificationCategory.attendance,
          createdAt: DateTime.now(),
          isRead: false,
        ),
      );

      state = state.copyWith(
        processState: AttendanceProcessState.success,
        stateType: AttendanceStateType.offlinePendingSync,
        message: response.message ??
            'تم تسجيل الحضور بدون اتصال وفي انتظار مراجعة الـ HR عند المزامنة.',
      );
      return true;
    } else {
      state = state.copyWith(
        processState: AttendanceProcessState.error,
        stateType: AttendanceStateType.serverRejected,
        message: response.message ?? 'تم رفض تسجيل الحضور من قبل الخادم.',
      );
      return false;
    }
  }

  /// Syncs offline pending records when connectivity is restored
  Future<int> syncPendingAttendance() async {
    state = state.copyWith(isSyncing: true);
    try {
      final attendanceRepo = _ref.read(attendanceRepositoryProvider);
      final count = await attendanceRepo.syncPendingAttendance();
      state = state.copyWith(
        isSyncing: false,
        message: count > 0
            ? 'تمت مزامنة $count سجلات بنجاح'
            : 'لا توجد سجلات معلقة للمزامنة',
      );
      return count;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        message: 'فشلت المزامنة، يرجى إعادة المحاولة',
      );
      return 0;
    }
  }

  void resetState() {
    state = const AttendanceFlowState();
  }
}

final attendanceFlowProvider =
    StateNotifierProvider<AttendanceFlowNotifier, AttendanceFlowState>((ref) {
      return AttendanceFlowNotifier(ref);
    });

/// Master state machine determining the exact current UI & business state.
final attendanceStateProvider = Provider<AttendanceStateType>((ref) {
  final summary = ref.watch(attendanceSummaryProvider);
  final flowState = ref.watch(attendanceFlowProvider);
  final shiftStatus = ref.watch(workScheduleShiftStatusProvider);
  final demo = ref.watch(demoControlsProvider);

  // 1. Process / Action states
  if (flowState.processState == AttendanceProcessState.checkingLocation) {
    return flowState.stateType;
  }
  if (flowState.processState == AttendanceProcessState.authenticatingBiometric) {
    return AttendanceStateType.verifyingBiometric;
  }
  if (flowState.processState == AttendanceProcessState.submitting) {
    return summary.hasCheckedIn
        ? AttendanceStateType.checkingOut
        : AttendanceStateType.checkingIn;
  }
  if (flowState.processState == AttendanceProcessState.error) {
    return flowState.stateType;
  }

  // 2. Completed State
  if (summary.hasCheckedOut) {
    return AttendanceStateType.workdayCompleted;
  }

  // 3. Checked In State
  if (summary.hasCheckedIn) {
    if (summary.checkIn?.isOffline == true) {
      return AttendanceStateType.offlinePendingSync;
    }
    return AttendanceStateType.checkedIn;
  }

  // 4. Location & Permissions Check
  final loc = flowState.locationResult;
  if (loc != null) {
    if (loc.isPermissionDenied || demo.locationMode == MockLocationMode.permissionDenied) {
      return AttendanceStateType.locationPermissionDenied;
    }
    if (loc.isGpsDisabled || demo.locationMode == MockLocationMode.gpsDisabled) {
      return AttendanceStateType.locationServiceDisabled;
    }
    if (loc.status == LocationStatus.locationUnavailable || loc.status == LocationStatus.error) {
      return AttendanceStateType.locationUnavailable;
    }
    if (!loc.isInsideRange) {
      return AttendanceStateType.outsideWorkplace;
    }
  }

  // 5. Shift Schedule Check
  if (shiftStatus.isBeforeShift) {
    return AttendanceStateType.beforeShift;
  }

  return AttendanceStateType.readyForCheckIn;
});

// ══════════════════════════════════════════════════════════════════
// 6. Requests (Advances / Permissions / Vacations)
// ══════════════════════════════════════════════════════════════════

final advancesRepositoryProvider = Provider<AdvancesRepository>((ref) {
  return MockAdvancesRepository(ref);
});

/// Advances — reactive: rebuilds when MockDatabase.advances changes.
final advancesListProvider = Provider<List<AdvanceRequest>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.advances.where((a) => a.employeeId == empId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final permissionsRepositoryProvider = Provider<PermissionsRepository>((ref) {
  return MockPermissionsRepository(ref);
});

/// Permissions list — reactive.
final permissionsListProvider = Provider<List<PermissionRequest>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.permissions.where((p) => p.employeeId == empId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final vacationsRepositoryProvider = Provider<VacationsRepository>((ref) {
  return MockVacationsRepository(ref);
});

/// Vacations list — reactive.
final vacationsListProvider = Provider<List<VacationRequest>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.vacations.where((v) => v.employeeId == empId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  final adv = ref.watch(advancesRepositoryProvider);
  final perm = ref.watch(permissionsRepositoryProvider);
  final vac = ref.watch(vacationsRepositoryProvider);
  return MockRequestsRepository(
    advancesRepo: adv,
    permissionsRepo: perm,
    vacationsRepo: vac,
  );
});

/// Unified requests list — reactive, sorted by date descending.
final allRequestsProvider = Provider<List<UnifiedRequestItem>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  final isArabic = ref.watch(settingsProvider).locale.languageCode == 'ar';

  final list = <UnifiedRequestItem>[
    ...db.advances
        .where((a) => a.employeeId == empId)
        .map((a) => UnifiedRequestItem.fromAdvance(a, isArabic)),
    ...db.permissions
        .where((p) => p.employeeId == empId)
        .map((p) => UnifiedRequestItem.fromPermission(p, isArabic)),
    ...db.vacations
        .where((v) => v.employeeId == empId)
        .map((v) => UnifiedRequestItem.fromVacation(v, isArabic)),
  ];
  list.sort((a, b) => b.date.compareTo(a.date));
  return list;
});

// ══════════════════════════════════════════════════════════════════
// 7. Notifications — reactive, direct from MockDatabase
// ══════════════════════════════════════════════════════════════════

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return MockNotificationsRepository(ref);
});

/// All notifications sorted newest first.
final notificationsListProvider = Provider<List<AppNotification>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  return db.notifications.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Unread count — drives the badge on the bottom nav.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(mockDatabaseProvider).unreadNotificationsCount;
});

// ══════════════════════════════════════════════════════════════════
// 8. Deductions & HR Messages
// ══════════════════════════════════════════════════════════════════

final deductionRepositoryProvider = Provider<DeductionRepository>((ref) {
  return MockDeductionRepository(ref);
});

final deductionsListProvider = Provider<List<Deduction>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.deductions.where((d) => d.employeeId == empId).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

final hrMessageRepositoryProvider = Provider<HRMessageRepository>((ref) {
  return MockHRMessageRepository(ref);
});

final hrMessagesListProvider = Provider<List<HRMessage>>((ref) {
  final db = ref.watch(mockDatabaseProvider);
  final empId = db.session?.employeeId ?? db.employee.id;
  return db.hrMessages.where((m) => m.employeeId == empId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

// ══════════════════════════════════════════════════════════════════
// 9. Settings Provider
// ══════════════════════════════════════════════════════════════════

class SettingsNotifier extends StateNotifier<AppSettings> {
  final LocalStorage _storage;

  SettingsNotifier(this._storage) : super(const AppSettings()) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final themeStr = _storage.getString(AppConstants.keyThemeMode);
    final localeStr = _storage.getString(AppConstants.keyLocale);

    ThemeMode mode = ThemeMode.system;
    if (themeStr == 'light') mode = ThemeMode.light;
    if (themeStr == 'dark') mode = ThemeMode.dark;

    Locale loc = const Locale('ar');
    if (localeStr == 'en') loc = const Locale('en');

    state = state.copyWith(themeMode: mode, locale: loc);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await _storage.setString(AppConstants.keyThemeMode, val);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _storage.setString(AppConstants.keyLocale, locale.languageCode);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  final storage = ref.watch(localStorageProvider);
  return SettingsNotifier(storage);
});
