import 'package:uuid/uuid.dart';
import '../models/attendance_api_contracts.dart';
import '../models/device_integrity_result.dart';
import '../models/location_result.dart';
import '../models/network_risk_info.dart';

class AttendanceAuditLog {
  final String auditId;
  final String clientRequestId;
  final String employeeId;
  final String actionType;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double distanceMeters;
  final bool biometricVerified;
  final DeviceIntegrityStatus integrityStatus;
  final NetworkSecurityLevel networkSecurityLevel;
  final bool isOffline;
  final String decision;
  final String? note;

  const AttendanceAuditLog({
    required this.auditId,
    required this.clientRequestId,
    required this.employeeId,
    required this.actionType,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.distanceMeters,
    required this.biometricVerified,
    required this.integrityStatus,
    required this.networkSecurityLevel,
    required this.isOffline,
    required this.decision,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'auditId': auditId,
    'clientRequestId': clientRequestId,
    'employeeId': employeeId,
    'actionType': actionType,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'distanceMeters': distanceMeters,
    'biometricVerified': biometricVerified,
    'integrityStatus': integrityStatus.name,
    'networkSecurityLevel': networkSecurityLevel.name,
    'isOffline': isOffline,
    'decision': decision,
    'note': note,
  };
}

/// Service that creates and manages tamper-evident attendance audit logs.
class AttendanceAuditService {
  final _uuid = const Uuid();
  final List<AttendanceAuditLog> _inMemoryLogs = [];

  AttendanceAuditService();

  List<AttendanceAuditLog> get logs => List.unmodifiable(_inMemoryLogs);

  /// Generates a structured audit record from the verification attempt.
  AttendanceAuditLog logAttendanceAttempt({
    required AttendanceSubmissionRequest request,
    required LocationResult locationResult,
    required AttendanceVerificationResponse response,
  }) {
    final auditLog = AttendanceAuditLog(
      auditId: response.auditId ?? 'AUD-${_uuid.v4().substring(0, 8)}',
      clientRequestId: request.clientRequestId,
      employeeId: request.employeeId,
      actionType: request.attendanceType.name,
      timestamp: DateTime.now(),
      latitude: request.latitude,
      longitude: request.longitude,
      accuracy: request.accuracy,
      distanceMeters: request.distanceFromWorkplace,
      biometricVerified: request.biometricVerified,
      integrityStatus:
          request.integrityResult?.status ?? DeviceIntegrityStatus.unsupported,
      networkSecurityLevel:
          request.networkRisk?.securityLevel ?? NetworkSecurityLevel.normal,
      isOffline: request.isOfflineSubmission,
      decision: response.decision.name,
      note: response.message,
    );

    _inMemoryLogs.add(auditLog);
    return auditLog;
  }
}
