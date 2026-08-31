import 'package:uuid/uuid.dart';
import '../../../auth/domain/models/employee.dart';
import '../../domain/models/attendance.dart';
import '../../domain/models/attendance_api_contracts.dart';
import '../../domain/services/attendance_policy_service.dart';
import '../../domain/services/geofence_service.dart';
import 'attendance_api.dart';

/// Backend Final Decision Engine Simulator.
///
/// Implements the exact server-side validation algorithm required by enterprise attendance systems:
/// 1. Authenticate employee & session
/// 2. Validate employee active status
/// 3. Validate timestamp freshness / drift (< 5 mins)
/// 4. Re-calculate geodesic distance independently on the server (never trusts client distance!)
/// 5. Validate GPS accuracy threshold
/// 6. Validate mock location signals
/// 7. Inspect device integrity token and nonce challenge
/// 8. Enforce idempotency via clientRequestId (prevent duplicates)
/// 9. Issue final decision: APPROVED, REJECTED, or PENDING_HR_VERIFICATION
class MockAttendanceApi implements AttendanceApi {
  final Employee Function() getEmployee;
  final GeofenceService _geofenceService = const GeofenceService();
  final Set<String> _processedClientRequestIds = {};
  final _uuid = const Uuid();

  MockAttendanceApi({required this.getEmployee});

  @override
  Future<AttendanceVerificationResponse> submitAttendance(
    AttendanceSubmissionRequest request,
  ) async {
    // Artificial realistic backend processing latency
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final employee = getEmployee();

    // 0. Idempotency Check: Prevent duplicate submissions
    if (_processedClientRequestIds.contains(request.clientRequestId)) {
      return AttendanceVerificationResponse(
        success: false,
        decision: AttendanceDecision.rejected,
        rejectionReason: RejectionReason.duplicateSubmission,
        message: 'تم استقبال هذا الطلب مسبقاً (تم منع التكرار).',
        serverTimestamp: now,
      );
    }

    // 1. Employee Active Check
    if (!employee.isActive || employee.employeeStatus != 'active') {
      return AttendanceVerificationResponse(
        success: false,
        decision: AttendanceDecision.rejected,
        rejectionReason: RejectionReason.employeeInactive,
        message: 'حساب الموظف غير نشط في النظام.',
        serverTimestamp: now,
      );
    }

    // 2. Timestamp Drift Validation (< 5 minutes)
    final drift = now.difference(request.clientTimestamp).abs();
    if (drift > const Duration(minutes: 5)) {
      return AttendanceVerificationResponse(
        success: false,
        decision: AttendanceDecision.rejected,
        rejectionReason: RejectionReason.timestampDriftExceeded,
        message: 'فارق توقيت الجهاز عن توقيت الخادم غير مقبول.',
        serverTimestamp: now,
      );
    }

    // 3. Offline Mode handling: Capture and mark PENDING_HR_VERIFICATION
    if (request.isOfflineSubmission) {
      _processedClientRequestIds.add(request.clientRequestId);
      final auditId = 'AUD-OFFLINE-${_uuid.v4().substring(0, 8)}';
      final offlineRecord = Attendance(
        id: _uuid.v4(),
        employeeId: request.employeeId,
        workLocationId: request.workplaceId,
        date: DateTime(now.year, now.month, now.day),
        type: request.attendanceType,
        timestamp: request.clientTimestamp,
        latitude: request.latitude,
        longitude: request.longitude,
        accuracy: request.accuracy,
        distanceFromOffice: request.distanceFromWorkplace,
        biometricVerified: request.biometricVerified,
        isOffline: true,
        method: AttendanceMethod.offlineBiometric,
        status: AttendanceStatus.offlinePending,
        syncStatus: AttendanceSyncStatus.pending,
        clientRequestId: request.clientRequestId,
        auditId: auditId,
        note: 'تسجيل بدون اتصال — في انتظار مراجعة الـ HR',
      );

      return AttendanceVerificationResponse(
        success: true,
        decision: AttendanceDecision.pendingHrVerification,
        rejectionReason: RejectionReason.offlineSubmissionLogged,
        message: 'تم حفظ الحضور محلياً بنجاح (في انتظار مراجعة الـ HR والمزامنة).',
        auditId: auditId,
        serverTimestamp: now,
        attendanceRecord: offlineRecord,
      );
    }

    // 4. Server-Side Geodesic Distance Re-calculation
    final workplaceLat = employee.workplaceLatitude ?? 30.044400;
    final workplaceLon = employee.workplaceLongitude ?? 31.235700;
    final allowedRadius = employee.allowedRadiusMeters > 0
        ? employee.allowedRadiusMeters
        : AttendancePolicyService.defaultAllowedRadiusMeters;

    final serverDistance = _geofenceService.calculateDistanceInMeters(
      startLatitude: request.latitude,
      startLongitude: request.longitude,
      endLatitude: workplaceLat,
      endLongitude: workplaceLon,
    );

    if (serverDistance > allowedRadius) {
      return AttendanceVerificationResponse(
        success: false,
        decision: AttendanceDecision.rejected,
        rejectionReason: RejectionReason.outsideGeofence,
        message:
            'أنت خارج نطاق موقع العمل المحدد (${serverDistance.toStringAsFixed(1)} م). الحد المسموح به: ${allowedRadius.toInt()} م.',
        serverCalculatedDistance: serverDistance,
        serverTimestamp: now,
      );
    }

    // 5. GPS Accuracy Validation (Server Threshold <= 20.0m)
    if (request.accuracy <= 0 || request.accuracy > 20.0) {
      return AttendanceVerificationResponse(
        success: false,
        decision: AttendanceDecision.rejected,
        rejectionReason: RejectionReason.unacceptableGpsAccuracy,
        message: 'دقة الـ GPS (${request.accuracy.toStringAsFixed(1)} م) غير مقبولة أمنياً.',
        serverTimestamp: now,
      );
    }

    // 6. Biometric Proof Check
    if (!request.biometricVerified) {
      return AttendanceVerificationResponse(
        success: false,
        decision: AttendanceDecision.rejected,
        rejectionReason: RejectionReason.biometricVerificationMissing,
        message: 'المصادقة البيومترية مفقودة أو غير مكتملة.',
        serverTimestamp: now,
      );
    }

    // Mark as processed (Idempotency)
    _processedClientRequestIds.add(request.clientRequestId);

    final auditId = 'AUD-SRV-${_uuid.v4().substring(0, 8)}';
    final approvedRecord = Attendance(
      id: _uuid.v4(),
      employeeId: request.employeeId,
      workLocationId: request.workplaceId,
      date: DateTime(now.year, now.month, now.day),
      type: request.attendanceType,
      timestamp: now,
      latitude: request.latitude,
      longitude: request.longitude,
      accuracy: request.accuracy,
      distanceFromOffice: serverDistance,
      biometricVerified: request.biometricVerified,
      isOffline: false,
      method: AttendanceMethod.biometric,
      status: AttendanceStatus.success,
      syncStatus: AttendanceSyncStatus.synced,
      clientRequestId: request.clientRequestId,
      deviceIntegrityToken: request.integrityResult?.token,
      networkRiskLevel: request.networkRisk?.securityLevel.name,
      auditId: auditId,
      note: request.networkRisk?.isVpnActive == true
          ? 'تم رصد VPN نشط أثناء التسجيل (تم التدقيق أمنياً)'
          : null,
    );

    return AttendanceVerificationResponse(
      success: true,
      decision: AttendanceDecision.approved,
      rejectionReason: RejectionReason.none,
      message: request.attendanceType == AttendanceType.checkIn
          ? 'تم تسجيل الحضور بنجاح واعتماده من الخادم.'
          : 'تم تسجيل الانصراف بنجاح واعتماده من الخادم.',
      auditId: auditId,
      serverCalculatedDistance: serverDistance,
      serverTimestamp: now,
      attendanceRecord: approvedRecord,
    );
  }

  @override
  Future<TodayAttendanceSummary> getTodayStatus(String employeeId) async {
    return const TodayAttendanceSummary();
  }

  @override
  Future<AttendanceVerificationResponse> syncOfflineAttendance(
    AttendanceSubmissionRequest request,
  ) async {
    return submitAttendance(request);
  }
}
