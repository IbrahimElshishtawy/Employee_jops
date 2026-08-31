import '../../../auth/domain/models/employee.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../core/mock/models/app_session.dart';
import '../models/attendance.dart';
import '../models/attendance_api_contracts.dart';
import '../models/attendance_state_type.dart';
import '../models/attendance_verification_result.dart';
import '../models/location_result.dart';
import '../models/work_schedule.dart';
import '../repositories/attendance_repository.dart';
import 'attendance_audit_service.dart';
import 'attendance_policy_service.dart';
import 'biometric_service.dart';
import 'device_integrity_service.dart';
import 'geofence_service.dart';
import 'location_service.dart';
import 'mock_location_detector.dart';
import 'network_risk_service.dart';
import 'screen_overlay_detector.dart';
import 'work_schedule_service.dart';

/// Central Orchestrator coordinating the multi-factor enterprise attendance verification flow.
///
/// Execution Pipeline:
/// 1. Verify Cloud Session & Authentication
/// 2. Verify Screen Security & Overlay Protection
/// 3. Verify GPS Location, Accuracy & Workplace Geofence
/// 4. Authenticate Device Biometrics (Fingerprint / Face ID)
/// 5. Cloud Attendance Registration & Authoritative Backend Evaluation
class AttendanceSecurityVerificationOrchestrator {
  final LocationService locationService;
  final GeofenceService geofenceService;
  final MockLocationDetector mockLocationDetector;
  final ScreenOverlayDetector screenOverlayDetector;
  final BiometricService biometricService;
  final DeviceIntegrityService deviceIntegrityService;
  final NetworkRiskService networkRiskService;
  final WorkScheduleService workScheduleService;
  final AttendancePolicyService policyService;
  final AuthRepository authRepository;
  final AttendanceRepository attendanceRepository;
  final AttendanceAuditService auditService;

  const AttendanceSecurityVerificationOrchestrator({
    required this.locationService,
    required this.geofenceService,
    required this.mockLocationDetector,
    required this.screenOverlayDetector,
    required this.biometricService,
    required this.deviceIntegrityService,
    required this.networkRiskService,
    required this.workScheduleService,
    required this.policyService,
    required this.authRepository,
    required this.attendanceRepository,
    required this.auditService,
  });

  /// Executes the full sequential verification flow.
  Future<AttendanceSecurityVerificationResult> executeVerification({
    required Employee employee,
    required WorkSchedule workSchedule,
    required TodayAttendanceSummary todaySummary,
    required AppSession? session,
    required bool isCheckIn,
    required bool isOnline,
    void Function(AttendanceSecurityVerificationResult result)? onStepUpdate,
  }) async {
    final startTimestamp = DateTime.now();

    var currentResult = AttendanceSecurityVerificationResult(
      timestamp: startTimestamp,
    );

    void notifyProgress(AttendanceSecurityVerificationResult updated) {
      currentResult = updated;
      if (onStepUpdate != null) {
        onStepUpdate(currentResult);
      }
    }

    // ─────────────────────────────────────────────────────────────
    // 0. Work Schedule & Pre-requisites Validation
    // ─────────────────────────────────────────────────────────────
    if (!employee.isActive || employee.employeeStatus != 'active') {
      currentResult = currentResult.copyWith(
        errorMessage: 'حساب الموظف غير نشط حالياً في النظام.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    if (isCheckIn && todaySummary.hasCheckedIn) {
      currentResult = currentResult.copyWith(
        errorMessage: 'تم تسجيل الحضور لهذا اليوم مسبقاً.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    if (!isCheckIn && !todaySummary.hasCheckedIn) {
      currentResult = currentResult.copyWith(
        errorMessage: 'لم يتم تسجيل الحضور بعد، لا يمكن تسجيل الانصراف.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    if (!isCheckIn && todaySummary.hasCheckedOut) {
      currentResult = currentResult.copyWith(
        errorMessage: 'تم إكمال يوم العمل وتسجيل الانصراف مسبقاً.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    // ─────────────────────────────────────────────────────────────
    // 1. Cloud Authentication & Active Session Verification
    // ─────────────────────────────────────────────────────────────
    currentResult = currentResult.copyWith(
      cloudAuthenticationStatus: CloudAuthenticationStatus.authSessionChecking,
    );
    notifyProgress(currentResult);

    if (session != null) {
      if (!session.isActive) {
        currentResult = currentResult.copyWith(
          cloudAuthenticationStatus: CloudAuthenticationStatus.authSessionExpired,
          errorMessage: 'انتهت صلاحية جلسة العمل. يرجى إعادة تسجيل الدخول.',
        );
        notifyProgress(currentResult);
        return currentResult;
      }
      if (session.employeeId.isNotEmpty && session.employeeId != employee.id) {
        currentResult = currentResult.copyWith(
          cloudAuthenticationStatus: CloudAuthenticationStatus.authSessionInvalid,
          errorMessage: 'بيانات اعتماد الموظف غير متطابقة مع الجلسة الحالية.',
        );
        notifyProgress(currentResult);
        return currentResult;
      }
    } else {
      final currentUser = await authRepository.getCurrentUser();
      if (currentUser != null && currentUser.id != employee.id) {
        currentResult = currentResult.copyWith(
          cloudAuthenticationStatus: CloudAuthenticationStatus.authSessionInvalid,
          errorMessage: 'بيانات اعتماد الموظف غير متطابقة مع الجلسة الحالية.',
        );
        notifyProgress(currentResult);
        return currentResult;
      }
    }

    currentResult = currentResult.copyWith(
      cloudAuthenticationStatus: CloudAuthenticationStatus.authSessionValid,
    );
    notifyProgress(currentResult);

    // ─────────────────────────────────────────────────────────────
    // 2. Screen Security & Overlay Verification
    // ─────────────────────────────────────────────────────────────
    currentResult = currentResult.copyWith(
      screenSecurityStatus: ScreenSecurityStatus.checkingScreenSecurity,
    );
    notifyProgress(currentResult);

    final isOverlay = await screenOverlayDetector.isUnsafeOverlayDetected();
    if (isOverlay) {
      currentResult = currentResult.copyWith(
        screenSecurityStatus: ScreenSecurityStatus.screenObscured,
        errorMessage:
            'يوجد تطبيق آخر قد يظهر فوق التطبيق أو يحجب الشاشة.\nيرجى إغلاقه ثم المحاولة مرة أخرى.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    currentResult = currentResult.copyWith(
      screenSecurityStatus: ScreenSecurityStatus.screenSafe,
    );
    notifyProgress(currentResult);

    // ─────────────────────────────────────────────────────────────
    // 3. Geofence & Location Verification
    // ─────────────────────────────────────────────────────────────
    currentResult = currentResult.copyWith(
      geofenceStatus: GeofenceVerificationStatus.checkingLocation,
    );
    notifyProgress(currentResult);

    final isServiceEnabled = await locationService.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      currentResult = currentResult.copyWith(
        geofenceStatus: GeofenceVerificationStatus.locationServiceDisabled,
        errorMessage: 'خدمة تحديد المواقع (GPS) معطلة. يرجى تفعيلها للمتابعة.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    final locResult = await locationService.getCurrentLocation();

    if (locResult.status == LocationStatus.permissionDenied ||
        locResult.status == LocationStatus.permissionDeniedForever) {
      currentResult = currentResult.copyWith(
        geofenceStatus: GeofenceVerificationStatus.locationPermissionDenied,
        locationResult: locResult,
        errorMessage: 'يرجى السماح للتطبيق باستخدام موقعك الجغرافي لتسجيل الحضور.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    if (locResult.status == LocationStatus.gpsDisabled) {
      currentResult = currentResult.copyWith(
        geofenceStatus: GeofenceVerificationStatus.locationServiceDisabled,
        locationResult: locResult,
        errorMessage: 'خدمة تحديد المواقع (GPS) معطلة. يرجى تفعيلها للمتابعة.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    // Mock Location Detection
    final isMock = await mockLocationDetector.isMockLocation(locResult);
    if (isMock || locResult.isMockLocation || locResult.status == LocationStatus.mockLocationDetected) {
      currentResult = currentResult.copyWith(
        geofenceStatus: GeofenceVerificationStatus.mockLocationDetected,
        locationResult: locResult,
        errorMessage: 'لا يمكن تسجيل الحضور باستخدام موقع غير موثوق (Mock Location).',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    // Accuracy Check
    if (!policyService.isAccuracyAcceptable(locResult.accuracyMeters) ||
        locResult.status == LocationStatus.lowAccuracy) {
      currentResult = currentResult.copyWith(
        geofenceStatus: GeofenceVerificationStatus.lowLocationAccuracy,
        locationResult: locResult,
        errorMessage:
            'دقة الموقع الجغرافي غير كافية (${locResult.accuracyMeters.toStringAsFixed(1)} م). يرجى الانتقال إلى مكان مكشوف.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    // Dynamic Workplace Geofence Check (uses configurable employee allowed radius)
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

    final updatedLocResult = locResult.copyWith(
      distanceFromOfficeMeters: calculatedDistance,
    );

    if (calculatedDistance > allowedRadius) {
      currentResult = currentResult.copyWith(
        geofenceStatus: GeofenceVerificationStatus.outsideGeofence,
        locationResult: updatedLocResult,
        errorMessage:
            'أنت خارج نطاق موقع العمل المحدد (${calculatedDistance.toStringAsFixed(1)} م، المسموح به: ${allowedRadius.toInt()} م).',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    currentResult = currentResult.copyWith(
      geofenceStatus: GeofenceVerificationStatus.insideGeofence,
      locationResult: updatedLocResult,
    );
    notifyProgress(currentResult);

    // ─────────────────────────────────────────────────────────────
    // 4. Device Biometric Authentication
    // ─────────────────────────────────────────────────────────────
    currentResult = currentResult.copyWith(
      biometricStatus: BiometricVerificationStatus.biometricAuthenticating,
    );
    notifyProgress(currentResult);

    final bioResult = await biometricService.authenticate(
      reason: isCheckIn
          ? 'تأكيد الحضور عبر بصمة الإصبع أو Face ID'
          : 'تأكيد الانصراف عبر بصمة الإصبع أو Face ID',
    );

    if (bioResult == BiometricAuthResult.cancelled) {
      currentResult = currentResult.copyWith(
        biometricStatus: BiometricVerificationStatus.biometricCancelled,
        errorMessage: 'تم إلغاء المصادقة البيومترية من قبل المستخدم.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    if (bioResult == BiometricAuthResult.notAvailable) {
      currentResult = currentResult.copyWith(
        biometricStatus: BiometricVerificationStatus.biometricNotAvailable,
        errorMessage: 'المصادقة البيومترية غير متوفرة أو غير مفعلة على هذا الجهاز.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    if (bioResult != BiometricAuthResult.success) {
      currentResult = currentResult.copyWith(
        biometricStatus: BiometricVerificationStatus.biometricFailed,
        errorMessage: 'فشلت المصادقة البيومترية. يرجى المحاولة مجدداً.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }

    final biometricToken = 'BIO-PROOF-${DateTime.now().millisecondsSinceEpoch}-${(session?.sessionId ?? employee.id).hashCode}';

    currentResult = currentResult.copyWith(
      biometricStatus: BiometricVerificationStatus.biometricSuccess,
      biometricToken: biometricToken,
    );
    notifyProgress(currentResult);

    // ─────────────────────────────────────────────────────────────
    // 5. Cloud Attendance Registration & Authoritative Decision
    // ─────────────────────────────────────────────────────────────
    currentResult = currentResult.copyWith(
      attendanceRegistrationStatus: CloudAttendanceRegistrationStatus.registering,
    );
    notifyProgress(currentResult);

    final integrityResult = await deviceIntegrityService.requestIntegrityToken(
      nonce: deviceIntegrityService.generateNonce(),
    );
    final networkRisk = await networkRiskService.evaluateNetworkRisk();

    final clientRequestId = 'REQ-${DateTime.now().millisecondsSinceEpoch}-${employee.id.hashCode}';
    final submissionRequest = AttendanceSubmissionRequest(
      clientRequestId: clientRequestId,
      employeeId: employee.id,
      attendanceType: isCheckIn ? AttendanceType.checkIn : AttendanceType.checkOut,
      latitude: updatedLocResult.latitude,
      longitude: updatedLocResult.longitude,
      accuracy: updatedLocResult.accuracyMeters,
      clientTimestamp: DateTime.now(),
      workplaceId: employee.workLocationId ?? 'LOC-CAIRO-HQ',
      distanceFromWorkplace: calculatedDistance,
      biometricVerified: true,
      biometricProofToken: biometricToken,
      integrityResult: integrityResult,
      networkRisk: networkRisk,
      isOfflineSubmission: !isOnline,
    );

    final response = await attendanceRepository.submitAttendanceRequest(submissionRequest);

    // Audit Logging
    auditService.logAttendanceAttempt(
      request: submissionRequest,
      locationResult: updatedLocResult,
      response: response,
    );

    if (response.isApproved) {
      currentResult = currentResult.copyWith(
        attendanceRegistrationStatus: CloudAttendanceRegistrationStatus.registered,
        integrityResult: integrityResult,
        networkRisk: networkRisk,
        response: response,
        errorMessage: null,
      );
      notifyProgress(currentResult);
      return currentResult;
    } else if (response.isPendingHr) {
      currentResult = currentResult.copyWith(
        attendanceRegistrationStatus: CloudAttendanceRegistrationStatus.offlineQueued,
        integrityResult: integrityResult,
        networkRisk: networkRisk,
        response: response,
        errorMessage: response.message,
      );
      notifyProgress(currentResult);
      return currentResult;
    } else {
      currentResult = currentResult.copyWith(
        attendanceRegistrationStatus: CloudAttendanceRegistrationStatus.rejected,
        integrityResult: integrityResult,
        networkRisk: networkRisk,
        response: response,
        errorMessage: response.message ?? 'تم رفض تسجيل الحضور من قبل الخادم.',
      );
      notifyProgress(currentResult);
      return currentResult;
    }
  }
}
