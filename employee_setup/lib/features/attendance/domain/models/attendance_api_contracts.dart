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

  factory AttendanceSubmissionRequest.fromJson(Map<String, dynamic> json) =>
      AttendanceSubmissionRequest(
        clientRequestId: json['clientRequestId'] as String,
        employeeId: json['employeeId'] as String,
        attendanceType: AttendanceType.values.byName(
          json['attendanceType'] as String,
        ),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num).toDouble(),
        clientTimestamp: DateTime.parse(json['clientTimestamp'] as String),
        workplaceId: json['workplaceId'] as String,
        distanceFromWorkplace:
            (json['distanceFromWorkplace'] as num).toDouble(),
        biometricVerified: json['biometricVerified'] as bool,
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
    this.rejectionReason = RejectionReason.none,
    this.message,
    this.auditId,
    this.serverCalculatedDistance,
    required this.serverTimestamp,
    this.attendanceRecord,
  });

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
