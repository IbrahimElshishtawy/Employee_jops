import 'attendance.dart';
import 'device_integrity_result.dart';
import 'network_risk_info.dart';

enum AttendanceDecision {
  approved,
  rejected,
  pendingHrVerification,
}

enum RejectionReason {
  none,
  employeeInactive,
  outsideWorkSchedule,
  outsideGeofence,
  unacceptableGpsAccuracy,
  mockLocationDetected,
  biometricVerificationMissing,
  deviceIntegrityInvalid,
  duplicateSubmission,
  timestampDriftExceeded,
  offlineSubmissionLogged,
  serverInternalError,
}

/// Idempotent submission payload for check-in / check-out.
class AttendanceSubmissionRequest {
  final String clientRequestId; // Unique UUID for idempotency
  final String employeeId;
  final AttendanceType attendanceType;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime clientTimestamp;
  final String workplaceId;
  final double distanceFromWorkplace; // Telemetry provided by client
  final bool biometricVerified;
  final String? biometricProofToken;
  final DeviceIntegrityResult? integrityResult;
  final NetworkRiskInfo? networkRisk;
  final bool isOfflineSubmission;

  const AttendanceSubmissionRequest({
    required this.clientRequestId,
    required this.employeeId,
    required this.attendanceType,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.clientTimestamp,
    required this.workplaceId,
    required this.distanceFromWorkplace,
    required this.biometricVerified,
    this.biometricProofToken,
    this.integrityResult,
    this.networkRisk,
    this.isOfflineSubmission = false,
  });

  Map<String, dynamic> toJson() => {
    'clientRequestId': clientRequestId,
    'employeeId': employeeId,
    'attendanceType': attendanceType.name,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'clientTimestamp': clientTimestamp.toIso8601String(),
    'workplaceId': workplaceId,
    'distanceFromWorkplace': distanceFromWorkplace,
    'biometricVerified': biometricVerified,
    'biometricProofToken': biometricProofToken,
    'integrityResult': integrityResult?.toJson(),
    'networkRisk': networkRisk?.toJson(),
    'isOfflineSubmission': isOfflineSubmission,
  };

  /// Serializes into exact backend CheckInDto / CheckOutDto for NestJS Fastify validation
  Map<String, dynamic> toBackendDto() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'requestId': clientRequestId,
    'method': 'GPS',
    'biometricVerified': biometricVerified,
    if (integrityResult?.isMockLocationDetected != null)
      'isMockLocation': integrityResult!.isMockLocationDetected,
    if (networkRisk?.isVpnActive != null)
      'isVpn': networkRisk!.isVpnActive,
    if (integrityResult?.isRootedOrJailbroken != null)
      'isJailbroken': integrityResult!.isRootedOrJailbroken,
  };

  factory AttendanceSubmissionRequest.fromJson(Map<String, dynamic> json) =>
      AttendanceSubmissionRequest(
        clientRequestId: json['clientRequestId'] as String? ?? json['requestId'] as String? ?? '',
        employeeId: json['employeeId'] as String? ?? '',
        attendanceType: json['attendanceType'] != null
            ? AttendanceType.values.byName(json['attendanceType'] as String)
            : AttendanceType.checkIn,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num).toDouble(),
        clientTimestamp: json['clientTimestamp'] != null
            ? DateTime.parse(json['clientTimestamp'] as String)
            : DateTime.now(),
        workplaceId: json['workplaceId'] as String? ?? '',
        distanceFromWorkplace:
            (json['distanceFromWorkplace'] as num?)?.toDouble() ?? 0.0,
        biometricVerified: json['biometricVerified'] as bool? ?? false,
        biometricProofToken: json['biometricProofToken'] as String?,
        integrityResult: json['integrityResult'] != null
            ? DeviceIntegrityResult.fromJson(
                json['integrityResult'] as Map<String, dynamic>,
              )
            : null,
        networkRisk: json['networkRisk'] != null
            ? NetworkRiskInfo.fromJson(
                json['networkRisk'] as Map<String, dynamic>,
              )
            : null,
        isOfflineSubmission: json['isOfflineSubmission'] as bool? ?? false,
      );
}

/// Server verification response — the backend is the final decision maker.
class AttendanceVerificationResponse {
  final bool success;
  final AttendanceDecision decision;
  final RejectionReason rejectionReason;
  final String? message;
  final String? auditId;
  final double? serverCalculatedDistance;
  final DateTime serverTimestamp;
  final Attendance? attendanceRecord;

  const AttendanceVerificationResponse({
    required this.success,
    required this.decision,
    required this.rejectionReason,
    this.message,
    this.auditId,
    this.serverCalculatedDistance,
    required this.serverTimestamp,
    this.attendanceRecord,
  });

  factory AttendanceVerificationResponse.fromBackendJson(
    Map<String, dynamic> json, {
    AttendanceType type = AttendanceType.checkIn,
    String? employeeId,
  }) {
    final success = json['success'] as bool? ?? true;
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    Attendance? record;
    if (data.isNotEmpty) {
      final now = DateTime.now();
      final checkInTime = data['checkIn'] != null ? DateTime.tryParse(data['checkIn'] as String) : now;
      final checkOutTime = data['checkOut'] != null ? DateTime.tryParse(data['checkOut'] as String) : null;

      record = Attendance(
        id: data['id'] as String? ?? 'ATT-${now.millisecondsSinceEpoch}',
        employeeId: data['employeeId'] as String? ?? employeeId ?? 'EMP-001',
        date: data['date'] != null ? DateTime.tryParse(data['date'] as String) ?? now : now,
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
        status: (type == AttendanceType.checkIn && checkOutTime == null)
            ? AttendanceStateType.checkedIn
            : AttendanceStateType.checkedOut,
        verificationMethod: 'GPS',
        verificationStatus: 'VERIFIED',
      );
    }

    return AttendanceVerificationResponse(
      success: success,
      decision: success ? AttendanceDecision.approved : AttendanceDecision.rejected,
      rejectionReason: success ? RejectionReason.none : RejectionReason.serverInternalError,
      message: json['message'] as String? ?? (success ? 'Punch recorded successfully' : 'Punch rejected'),
      auditId: data['id'] as String?,
      serverTimestamp: DateTime.now(),
      attendanceRecord: record,
    );
  }

  bool get isApproved => decision == AttendanceDecision.approved;
  bool get isPendingHr => decision == AttendanceDecision.pendingHrVerification;

  Map<String, dynamic> toJson() => {
    'success': success,
    'decision': decision.name,
    'rejectionReason': rejectionReason.name,
    'message': message,
    'auditId': auditId,
    'serverCalculatedDistance': serverCalculatedDistance,
    'serverTimestamp': serverTimestamp.toIso8601String(),
    'attendanceRecord': attendanceRecord?.toJson(),
  };

  factory AttendanceVerificationResponse.fromJson(Map<String, dynamic> json) =>
      AttendanceVerificationResponse(
        success: json['success'] as bool,
        decision: AttendanceDecision.values.byName(
          json['decision'] as String? ?? 'rejected',
        ),
        rejectionReason: RejectionReason.values.byName(
          json['rejectionReason'] as String? ?? 'none',
        ),
        message: json['message'] as String?,
        auditId: json['auditId'] as String?,
        serverCalculatedDistance:
            (json['serverCalculatedDistance'] as num?)?.toDouble(),
        serverTimestamp: DateTime.parse(json['serverTimestamp'] as String),
        attendanceRecord: json['attendanceRecord'] != null
            ? Attendance.fromJson(
                json['attendanceRecord'] as Map<String, dynamic>,
              )
            : null,
      );
}
