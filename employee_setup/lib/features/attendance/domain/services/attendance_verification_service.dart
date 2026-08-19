import '../../../auth/domain/models/employee.dart';
import '../models/attendance.dart';
import '../models/attendance_state_type.dart';
import '../models/device_integrity_result.dart';
import '../models/location_result.dart';
import '../models/network_risk_info.dart';
import '../models/work_schedule.dart';
import 'attendance_policy_service.dart';
import 'biometric_service.dart';
import 'device_integrity_service.dart';
import 'geofence_service.dart';
import 'location_service.dart';
import 'mock_location_detector.dart';
import 'network_risk_service.dart';
import 'work_schedule_service.dart';

/// Pre-submission client verification outcome.
class VerificationStepResult<T> {
  final bool isSuccess;
  final AttendanceStateType? failureState;
  final String? errorMessage;
  final T? data;

  const VerificationStepResult.success(this.data)
      : isSuccess = true,
        failureState = null,
        errorMessage = null;

  const VerificationStepResult.failure({
    required this.failureState,
    required this.errorMessage,
  })  : isSuccess = false,
        data = null;
}

/// Domain service orchestrating the multi-factor attendance verification pipeline.
class AttendanceVerificationService {
  final LocationService locationService;
  final GeofenceService geofenceService;
  final MockLocationDetector mockLocationDetector;
  final BiometricService biometricService;
  final DeviceIntegrityService deviceIntegrityService;
  final NetworkRiskService networkRiskService;
  final WorkScheduleService workScheduleService;
  final AttendancePolicyService policyService;

  const AttendanceVerificationService({
    required this.locationService,
    required this.geofenceService,
    required this.mockLocationDetector,
    required this.biometricService,
    required this.deviceIntegrityService,
    required this.networkRiskService,
    required this.workScheduleService,
    required this.policyService,
  });

  /// 1. Verifies work schedule prerequisites.
  VerificationStepResult<bool> verifyWorkSchedule({
    required Employee employee,
    required WorkSchedule workSchedule,
    required TodayAttendanceSummary todaySummary,
    required bool isCheckIn,
  }) {
    if (!employee.isActive || employee.employeeStatus != 'active') {
      return const VerificationStepResult.failure(
        failureState: AttendanceStateType.workScheduleInvalid,
        errorMessage: 'حساب الموظف غير نشط حالياً.',
      );
    }

    if (isCheckIn && todaySummary.hasCheckedIn) {
      return const VerificationStepResult.failure(
        failureState: AttendanceStateType.alreadyCheckedIn,
        errorMessage: 'تم تسجيل الحضور لهذا اليوم مسبقاً.',
      );
    }

    if (!isCheckIn && !todaySummary.hasCheckedIn) {
      return const VerificationStepResult.failure(
        failureState: AttendanceStateType.error,
        errorMessage: 'لم يتم تسجيل الحضور بعد، لا يمكن تسجيل الانصراف.',
      );
    }

    if (!isCheckIn && todaySummary.hasCheckedOut) {
      return const VerificationStepResult.failure(
        failureState: AttendanceStateType.alreadyCheckedOut,
        errorMessage: 'تم إكمال يوم العمل وتسجيل الانصراف مسبقاً.',
      );
    }

    return const VerificationStepResult.success(true);
  }

  /// 2. Verifies GPS location, permissions, accuracy, staleness, mock signals, and geofence.
  Future<VerificationStepResult<LocationResult>> verifyLocation({
    required Employee employee,
  }) async {
    final isServiceEnabled = await locationService.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return const VerificationStepResult.failure(
        failureState: AttendanceStateType.locationServiceDisabled,
        errorMessage: 'خدمة تحديد المواقع (GPS) معطلة. يرجى تفعيلها للمتابعة.',
      );
    }

    final locResult = await locationService.getCurrentLocation();

    if (locResult.status == LocationStatus.permissionDenied ||
        locResult.status == LocationStatus.permissionDeniedForever) {
      return const VerificationStepResult.failure(
        failureState: AttendanceStateType.locationPermissionDenied,
        errorMessage: 'يرجى السماح للتطبيق باستخدام موقعك الجغرافي.',
      );
    }

    if (locResult.status == LocationStatus.gpsDisabled) {
      return const VerificationStepResult.failure(
        failureState: AttendanceStateType.locationServiceDisabled,
        errorMessage: 'يرجى تفعيل خدمة الموقع الجغرافي على هاتفك.',
      );
    }

    // Mock Location Detection
    final isMock = await mockLocationDetector.isMockLocation(locResult);
    if (isMock || locResult.isMockLocation || locResult.status == LocationStatus.mockLocationDetected) {
      return const VerificationStepResult.failure(
        failureState: AttendanceStateType.mockLocationDetected,
        errorMessage: 'تم رصد استخدام موقع وهمي (Mock Location). لا يمكن تسجيل الحضور باستخدام موقع غير موثوق.',
      );
    }

    // Accuracy Check
    if (!policyService.isAccuracyAcceptable(locResult.accuracyMeters) ||
        locResult.status == LocationStatus.lowAccuracy) {
      return VerificationStepResult.failure(
        failureState: AttendanceStateType.lowLocationAccuracy,
        errorMessage: 'دقة الموقع غير كافية (${locResult.accuracyMeters.toStringAsFixed(1)} م). يرجى الانتقال لمكان مكشوف.',
      );
    }

    // Workplace Geofence Check (Dynamic employee workplace & radius)
    final allowedRadius = employee.allowedRadiusMeters > 0
        ? employee.allowedRadiusMeters
        : AttendancePolicyService.defaultAllowedRadiusMeters;

    final workplaceLat = employee.workplaceLatitude ?? 30.044400;
    final workplaceLon = employee.workplaceLongitude ?? 31.235700;

    final calculatedDistance = geofenceService.calculateDistanceInMeters(
      startLatitude: locResult.latitude,
      startLongitude: locResult.longitude,
      endLatitude: workplaceLat,
      endLongitude: workplaceLon,
    );

    if (calculatedDistance > allowedRadius) {
      return VerificationStepResult.failure(
        failureState: AttendanceStateType.outsideWorkplace,
        errorMessage: 'أنت خارج نطاق موقع العمل (${calculatedDistance.toStringAsFixed(1)} م، المسموح: ${allowedRadius.toInt()} م).',
      );
    }

    return VerificationStepResult.success(
      locResult.copyWith(distanceFromOfficeMeters: calculatedDistance),
    );
  }

  /// 3. Authenticates device biometric presence.
  Future<VerificationStepResult<String>> verifyBiometrics({
    required bool isCheckIn,
  }) async {
    final bioResult = await biometricService.authenticate(
      reason: isCheckIn
          ? 'تأكيد الحضور عبر بصمة الإصبع أو Face ID'
          : 'تأكيد الانصراف عبر بصمة الإصبع أو Face ID',
    );

    if (bioResult == BiometricAuthResult.success) {
      final token = 'BIO-AUTH-${DateTime.now().millisecondsSinceEpoch}';
      return VerificationStepResult.success(token);
    }

    if (bioResult == BiometricAuthResult.cancelled) {
      return const VerificationStepResult.failure(
        failureState: AttendanceStateType.biometricFailed,
        errorMessage: 'تم إلغاء المصادقة البيومترية.',
      );
    }

    if (bioResult == BiometricAuthResult.notAvailable) {
      return const VerificationStepResult.failure(
        failureState: AttendanceStateType.biometricUnavailable,
        errorMessage: 'المصادقة البيومترية غير متوفرة على هذا الجهاز.',
      );
    }

    return const VerificationStepResult.failure(
      failureState: AttendanceStateType.biometricFailed,
      errorMessage: 'فشلت المصادقة البيومترية، يرجى إعادة المحاولة.',
    );
  }

  /// 4. Requests device integrity attestation token.
  Future<DeviceIntegrityResult> acquireDeviceIntegrityToken() async {
    final nonce = deviceIntegrityService.generateNonce();
    return await deviceIntegrityService.requestIntegrityToken(nonce: nonce);
  }

  /// 5. Collects network and VPN risk telemetry.
  Future<NetworkRiskInfo> collectNetworkRisk() async {
    return await networkRiskService.evaluateNetworkRisk();
  }
}
