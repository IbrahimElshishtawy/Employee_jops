import '../../../employees/domain/entities/employee_entity.dart';

enum AttendanceStatus {
  present('PRESENT', 'Present'),
  late('LATE', 'Late'),
  absent('ABSENT', 'Absent'),
  earlyDeparture('EARLY_DEPARTURE', 'Early Departure'),
  overtime('OVERTIME', 'Overtime');

  final String key;
  final String label;

  const AttendanceStatus(this.key, this.label);

  static AttendanceStatus fromKey(String? key) {
    if (key == null) return AttendanceStatus.present;
    return AttendanceStatus.values.firstWhere(
      (s) => s.key.toUpperCase() == key.toUpperCase(),
      orElse: () => AttendanceStatus.present,
    );
  }
}

enum SecurityStatus {
  normal('NORMAL', 'Verified Secure'),
  suspicious('SUSPICIOUS', 'Security Flagged'),
  rejected('REJECTED', 'Security Rejected');

  final String key;
  final String label;

  const SecurityStatus(this.key, this.label);

  static SecurityStatus fromKey(String? key) {
    if (key == null) return SecurityStatus.normal;
    return SecurityStatus.values.firstWhere(
      (s) => s.key.toUpperCase() == key.toUpperCase(),
      orElse: () => SecurityStatus.normal,
    );
  }
}

enum AttendanceEventType {
  checkInAttempted('CHECK_IN_ATTEMPTED', 'Check-in Attempted'),
  gpsValidated('GPS_VALIDATED', 'GPS Coordinates Validated'),
  geofenceValidated('GEOFENCE_VALIDATED', 'Geofence Boundary Verified'),
  checkInAccepted('CHECK_IN_ACCEPTED', 'Check-in Accepted'),
  checkInRejected('CHECK_IN_REJECTED', 'Check-in Rejected'),
  checkOutAttempted('CHECK_OUT_ATTEMPTED', 'Check-out Attempted'),
  checkOutAccepted('CHECK_OUT_ACCEPTED', 'Check-out Accepted'),
  checkOutRejected('CHECK_OUT_REJECTED', 'Check-out Rejected'),
  manualCorrection('MANUAL_CORRECTION', 'Manual HR Correction');

  final String key;
  final String label;

  const AttendanceEventType(this.key, this.label);

  static AttendanceEventType fromKey(String? key) {
    if (key == null) return AttendanceEventType.checkInAttempted;
    return AttendanceEventType.values.firstWhere(
      (e) => e.key.toUpperCase() == key.toUpperCase(),
      orElse: () => AttendanceEventType.checkInAttempted,
    );
  }
}

/// Tamper-evident step in the attendance punch lifecycle
class AttendanceEvent {
  final String id;
  final AttendanceEventType eventType;
  final DateTime timestamp;
  final String description;
  final Map<String, dynamic>? metadata;

  const AttendanceEvent({
    required this.id,
    required this.eventType,
    required this.timestamp,
    required this.description,
    this.metadata,
  });
}

/// Aggregated Attendance Statistics from backend
class AttendanceKpiSummary {
  final int totalEmployees;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int earlyDepartureCount;
  final int overtimeCount;
  final int offlinePendingCount;
  final int suspiciousCount;

  const AttendanceKpiSummary({
    required this.totalEmployees,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.earlyDepartureCount,
    required this.overtimeCount,
    required this.offlinePendingCount,
    required this.suspiciousCount,
  });
}

/// Domain entity representing an employee attendance punch event
class AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String? department;
  final String? workplaceId;
  final String workplaceName;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final int? lateMinutes;
  final int? overtimeMinutes;
  final String? rejectionReason;
  final bool isFlagged;

  // Telemetry & Geofence (Check-in)
  final double? checkInLat;
  final double? checkInLng;
  final double? checkInAccuracy;
  final double? checkInDistanceMeters;
  final bool? checkInGeofenceValid;

  // Telemetry & Geofence (Check-out)
  final double? checkOutLat;
  final double? checkOutLng;
  final double? checkOutAccuracy;
  final double? checkOutDistanceMeters;
  final bool? checkOutGeofenceValid;

  // Security signals & Device Info
  final SecurityStatus securityStatus;
  final List<String> securitySignals; // e.g. ["VPN Detected", "Mock Location", "Outside Geofence"]
  final String? deviceModel;
  final String? deviceOs;

  // Offline review status
  final bool isOfflinePending;
  final DateTime? offlineRecordedAt;
  final DateTime? offlineReviewedAt;
  final String? offlineReviewedBy;
  final String? offlineReviewNote;

  // Schedule information
  final String? scheduleName;
  final String? shiftStart;
  final String? shiftEnd;
  final int? gracePeriodMinutes;

  // Event audit trail
  final List<AttendanceEvent> events;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.department = 'Engineering',
    this.workplaceId = 'WP-001',
    required this.workplaceName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.lateMinutes,
    this.overtimeMinutes,
    this.rejectionReason,
    this.isFlagged = false,
    this.checkInLat,
    this.checkInLng,
    this.checkInAccuracy,
    this.checkInDistanceMeters,
    this.checkInGeofenceValid,
    this.checkOutLat,
    this.checkOutLng,
    this.checkOutAccuracy,
    this.checkOutDistanceMeters,
    this.checkOutGeofenceValid,
    this.securityStatus = SecurityStatus.normal,
    this.securitySignals = const [],
    this.deviceModel,
    this.deviceOs,
    this.isOfflinePending = false,
    this.offlineRecordedAt,
    this.offlineReviewedAt,
    this.offlineReviewedBy,
    this.offlineReviewNote,
    this.scheduleName,
    this.shiftStart,
    this.shiftEnd,
    this.gracePeriodMinutes,
    this.events = const [],
  });

  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    String? department,
    String? workplaceId,
    String? workplaceName,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    AttendanceStatus? status,
    int? lateMinutes,
    int? overtimeMinutes,
    String? rejectionReason,
    bool? isFlagged,
    double? checkInLat,
    double? checkInLng,
    double? checkInAccuracy,
    double? checkInDistanceMeters,
    bool? checkInGeofenceValid,
    double? checkOutLat,
    double? checkOutLng,
    double? checkOutAccuracy,
    double? checkOutDistanceMeters,
    bool? checkOutGeofenceValid,
    SecurityStatus? securityStatus,
    List<String>? securitySignals,
    String? deviceModel,
    String? deviceOs,
    bool? isOfflinePending,
    DateTime? offlineRecordedAt,
    DateTime? offlineReviewedAt,
    String? offlineReviewedBy,
    String? offlineReviewNote,
    String? scheduleName,
    String? shiftStart,
    String? shiftEnd,
    int? gracePeriodMinutes,
    List<AttendanceEvent>? events,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      department: department ?? this.department,
      workplaceId: workplaceId ?? this.workplaceId,
      workplaceName: workplaceName ?? this.workplaceName,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      overtimeMinutes: overtimeMinutes ?? this.overtimeMinutes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isFlagged: isFlagged ?? this.isFlagged,
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLng: checkInLng ?? this.checkInLng,
      checkInAccuracy: checkInAccuracy ?? this.checkInAccuracy,
      checkInDistanceMeters: checkInDistanceMeters ?? this.checkInDistanceMeters,
      checkInGeofenceValid: checkInGeofenceValid ?? this.checkInGeofenceValid,
      checkOutLat: checkOutLat ?? this.checkOutLat,
      checkOutLng: checkOutLng ?? this.checkOutLng,
      checkOutAccuracy: checkOutAccuracy ?? this.checkOutAccuracy,
      checkOutDistanceMeters: checkOutDistanceMeters ?? this.checkOutDistanceMeters,
      checkOutGeofenceValid: checkOutGeofenceValid ?? this.checkOutGeofenceValid,
      securityStatus: securityStatus ?? this.securityStatus,
      securitySignals: securitySignals ?? this.securitySignals,
      deviceModel: deviceModel ?? this.deviceModel,
      deviceOs: deviceOs ?? this.deviceOs,
      isOfflinePending: isOfflinePending ?? this.isOfflinePending,
      offlineRecordedAt: offlineRecordedAt ?? this.offlineRecordedAt,
      offlineReviewedAt: offlineReviewedAt ?? this.offlineReviewedAt,
      offlineReviewedBy: offlineReviewedBy ?? this.offlineReviewedBy,
      offlineReviewNote: offlineReviewNote ?? this.offlineReviewNote,
      scheduleName: scheduleName ?? this.scheduleName,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      events: events ?? this.events,
    );
  }
}

class AttendanceFilter {
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final AttendanceStatus? status;
  final String? workplaceId;
  final String? department;
  final SecurityStatus? securityStatus;
  final bool? isOfflinePending;
  final bool? isSuspicious;
  final int page;
  final int pageSize;

  const AttendanceFilter({
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.status,
    this.workplaceId,
    this.department,
    this.securityStatus,
    this.isOfflinePending,
    this.isSuspicious,
    this.page = 1,
    this.pageSize = 10,
  });
}

abstract class AttendanceRepository {
  Future<PaginatedList<AttendanceRecord>> getAttendanceRecords(AttendanceFilter filter);
  Future<AttendanceRecord> getAttendanceDetails(String id);
  Future<List<AttendanceEvent>> getAttendanceEvents(String recordId);
  Future<AttendanceKpiSummary> getAttendanceKpis({DateTime? date});
  Future<PaginatedList<AttendanceRecord>> getSuspiciousRecords(int page, int pageSize);
  Future<PaginatedList<AttendanceRecord>> getOfflineRecords(int page, int pageSize);
  Future<void> reviewOfflineRecord(String id, {required bool approve, String? reason});
  Future<AttendanceRecord> manualCorrection({
    required String employeeId,
    required DateTime date,
    required AttendanceStatus status,
    required DateTime checkInTime,
    required DateTime checkOutTime,
    required String reason,
  });
  Future<String> exportAttendanceReport(AttendanceFilter filter);
}
