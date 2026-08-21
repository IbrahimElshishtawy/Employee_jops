import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/attendance_record.dart';

/// Mock Attendance Repository with safe test records & authoritative security signals
class MockAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecord> _mockRecords = [
    AttendanceRecord(
      id: 'TEST-ATT-001',
      employeeId: 'TEST-EMP-001',
      employeeName: 'Alex Vance (Test)',
      employeeCode: 'CW-001',
      department: 'Engineering',
      workplaceId: 'WP-001',
      workplaceName: 'HQ Main Tower',
      date: DateTime.now(),
      checkInTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 55),
      checkOutTime: null,
      status: AttendanceStatus.present,
      checkInLat: 30.0444,
      checkInLng: 31.2357,
      checkInAccuracy: 6.2,
      checkInDistanceMeters: 28.5,
      checkInGeofenceValid: true,
      securityStatus: SecurityStatus.normal,
      deviceModel: 'Pixel 8 Pro (Test)',
      deviceOs: 'Android 14',
      scheduleName: 'Standard Core (09:00 - 17:00)',
      shiftStart: '09:00',
      shiftEnd: '17:00',
      gracePeriodMinutes: 15,
      events: [
        AttendanceEvent(
          id: 'EVT-001',
          eventType: AttendanceEventType.checkInAttempted,
          timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 54, 50),
          description: 'Mobile check-in request initiated from device',
        ),
        AttendanceEvent(
          id: 'EVT-002',
          eventType: AttendanceEventType.gpsValidated,
          timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 54, 55),
          description: 'GPS accuracy 6.2m validated against threshold (≤20m)',
        ),
        AttendanceEvent(
          id: 'EVT-003',
          eventType: AttendanceEventType.geofenceValidated,
          timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 54, 58),
          description: 'Location 28.5m inside authoritative HQ geofence polygon',
        ),
        AttendanceEvent(
          id: 'EVT-004',
          eventType: AttendanceEventType.checkInAccepted,
          timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 55, 0),
          description: 'Check-in accepted and verified on time',
        ),
      ],
    ),
    AttendanceRecord(
      id: 'TEST-ATT-002',
      employeeId: 'TEST-EMP-002',
      employeeName: 'Jordan Miller (Test)',
      employeeCode: 'CW-002',
      department: 'Human Resources',
      workplaceId: 'WP-001',
      workplaceName: 'HQ Main Tower',
      date: DateTime.now(),
      checkInTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 9, 25),
      checkOutTime: null,
      status: AttendanceStatus.late,
      lateMinutes: 25,
      checkInLat: 30.0442,
      checkInLng: 31.2359,
      checkInAccuracy: 8.5,
      checkInDistanceMeters: 42.0,
      checkInGeofenceValid: true,
      securityStatus: SecurityStatus.normal,
      deviceModel: 'iPhone 15 (Test)',
      deviceOs: 'iOS 17.4',
      scheduleName: 'Standard Core (09:00 - 17:00)',
      shiftStart: '09:00',
      shiftEnd: '17:00',
      gracePeriodMinutes: 15,
      events: [
        AttendanceEvent(
          id: 'EVT-005',
          eventType: AttendanceEventType.checkInAttempted,
          timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 9, 24, 50),
          description: 'Mobile check-in request initiated',
        ),
        AttendanceEvent(
          id: 'EVT-006',
          eventType: AttendanceEventType.checkInAccepted,
          timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 9, 25, 0),
          description: 'Check-in accepted with 25 minutes late arrival flag',
        ),
      ],
    ),
    AttendanceRecord(
      id: 'TEST-ATT-003',
      employeeId: 'TEST-EMP-003',
      employeeName: 'Taylor Morgan (Test)',
      employeeCode: 'CW-003',
      department: 'Operations',
      workplaceId: 'WP-002',
      workplaceName: 'Tech Hub Branch',
      date: DateTime.now(),
      checkInTime: null,
      checkOutTime: null,
      status: AttendanceStatus.absent,
      scheduleName: 'Morning Shift (08:00 - 16:00)',
      shiftStart: '08:00',
      shiftEnd: '16:00',
      gracePeriodMinutes: 10,
    ),
    AttendanceRecord(
      id: 'TEST-ATT-004',
      employeeId: 'TEST-EMP-004',
      employeeName: 'Samira Khan (Test)',
      employeeCode: 'CW-004',
      department: 'Finance',
      workplaceId: 'WP-001',
      workplaceName: 'HQ Main Tower',
      date: DateTime.now().subtract(const Duration(days: 1)),
      checkInTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 1, 8, 50),
      checkOutTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 1, 18, 15),
      status: AttendanceStatus.overtime,
      overtimeMinutes: 75,
      checkInLat: 30.0445,
      checkInLng: 31.2355,
      checkInAccuracy: 5.0,
      checkInDistanceMeters: 20.0,
      checkInGeofenceValid: true,
      checkOutLat: 30.0446,
      checkOutLng: 31.2356,
      checkOutAccuracy: 5.2,
      checkOutDistanceMeters: 22.0,
      checkOutGeofenceValid: true,
      securityStatus: SecurityStatus.normal,
      scheduleName: 'Standard Core (09:00 - 17:00)',
      shiftStart: '09:00',
      shiftEnd: '17:00',
      gracePeriodMinutes: 15,
    ),
    AttendanceRecord(
      id: 'TEST-ATT-005',
      employeeId: 'TEST-EMP-005',
      employeeName: 'Casey Davis (Test)',
      employeeCode: 'CW-005',
      department: 'Marketing',
      workplaceId: 'WP-002',
      workplaceName: 'Tech Hub Branch',
      date: DateTime.now().subtract(const Duration(days: 1)),
      checkInTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 1, 8, 58),
      checkOutTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 1, 15, 30),
      status: AttendanceStatus.earlyDeparture,
      checkInLat: 30.0125,
      checkInLng: 31.4125,
      checkInAccuracy: 7.0,
      checkInDistanceMeters: 35.0,
      checkInGeofenceValid: true,
      checkOutLat: 30.0126,
      checkOutLng: 31.4124,
      checkOutAccuracy: 8.0,
      checkOutDistanceMeters: 40.0,
      checkOutGeofenceValid: true,
      securityStatus: SecurityStatus.normal,
      scheduleName: 'Standard Core (09:00 - 17:00)',
      shiftStart: '09:00',
      shiftEnd: '17:00',
      gracePeriodMinutes: 15,
    ),
    // Suspicious Attendance Record (Security Flagged)
    AttendanceRecord(
      id: 'TEST-ATT-006',
      employeeId: 'TEST-EMP-003',
      employeeName: 'Taylor Morgan (Test)',
      employeeCode: 'CW-003',
      department: 'Operations',
      workplaceId: 'WP-002',
      workplaceName: 'Tech Hub Branch',
      date: DateTime.now().subtract(const Duration(days: 2)),
      checkInTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 2, 8, 12),
      status: AttendanceStatus.late,
      isFlagged: true,
      checkInLat: 30.0550,
      checkInLng: 31.2500,
      checkInAccuracy: 45.0,
      checkInDistanceMeters: 480.0,
      checkInGeofenceValid: false,
      securityStatus: SecurityStatus.suspicious,
      securitySignals: [
        'Outside workplace boundary (480m)',
        'Mock location signal detected',
        'VPN / proxy connection active',
        'Poor GPS accuracy (45m)',
      ],
      deviceModel: 'SM-G998B (Test Emulator)',
      deviceOs: 'Android 13',
      scheduleName: 'Morning Shift (08:00 - 16:00)',
      events: [
        AttendanceEvent(
          id: 'EVT-007',
          eventType: AttendanceEventType.checkInAttempted,
          timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 2, 8, 11, 40),
          description: 'Check-in attempted from remote coordinates',
        ),
        AttendanceEvent(
          id: 'EVT-008',
          eventType: AttendanceEventType.geofenceValidated,
          timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 2, 8, 11, 55),
          description: 'Geofence evaluation failed: 480m from Tech Hub perimeter',
        ),
      ],
    ),
    // Offline Attendance Record (Pending HR Review)
    AttendanceRecord(
      id: 'TEST-ATT-007',
      employeeId: 'TEST-EMP-001',
      employeeName: 'Alex Vance (Test)',
      employeeCode: 'CW-001',
      department: 'Engineering',
      workplaceId: 'WP-001',
      workplaceName: 'HQ Main Tower',
      date: DateTime.now().subtract(const Duration(days: 3)),
      checkInTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 3, 9, 2),
      checkOutTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 3, 17, 5),
      status: AttendanceStatus.present,
      isOfflinePending: true,
      offlineRecordedAt: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 3, 9, 2),
      checkInLat: 30.0443,
      checkInLng: 31.2358,
      checkInAccuracy: 9.0,
      checkInDistanceMeters: 30.0,
      checkInGeofenceValid: true,
      securityStatus: SecurityStatus.normal,
      deviceModel: 'Pixel 8 Pro (Test)',
      deviceOs: 'Android 14',
      scheduleName: 'Standard Core (09:00 - 17:00)',
      events: [
        AttendanceEvent(
          id: 'EVT-009',
          eventType: AttendanceEventType.checkInAttempted,
          timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 3, 9, 2),
          description: 'Offline punch stored in encrypted mobile vault (No network connectivity)',
        ),
        AttendanceEvent(
          id: 'EVT-010',
          eventType: AttendanceEventType.gpsValidated,
          timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 3, 17, 30),
          description: 'Offline batch synced to server upon network restoration. Pending HR review.',
        ),
      ],
    ),
  ];

  @override
  Future<PaginatedList<AttendanceRecord>> getAttendanceRecords(AttendanceFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var results = List<AttendanceRecord>.from(_mockRecords);

    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = filter.searchQuery!.trim().toLowerCase();
      results = results.where((r) =>
          r.employeeName.toLowerCase().contains(q) ||
          r.employeeCode.toLowerCase().contains(q) ||
          r.department.toLowerCase().contains(q) ||
          r.workplaceName.toLowerCase().contains(q)).toList();
    }

    if (filter.status != null) {
      results = results.where((r) => r.status == filter.status).toList();
    }

    if (filter.securityStatus != null) {
      results = results.where((r) => r.securityStatus == filter.securityStatus).toList();
    }

    if (filter.department != null && filter.department!.isNotEmpty) {
      results = results.where((r) => r.department.toLowerCase() == filter.department!.toLowerCase()).toList();
    }

    if (filter.workplaceId != null && filter.workplaceId!.isNotEmpty) {
      results = results.where((r) => r.workplaceId == filter.workplaceId).toList();
    }

    if (filter.isOfflinePending != null) {
      results = results.where((r) => r.isOfflinePending == filter.isOfflinePending).toList();
    }

    if (filter.isSuspicious != null) {
      results = results.where((r) => r.securityStatus == SecurityStatus.suspicious || r.isFlagged).toList();
    }

    if (filter.startDate != null) {
      results = results.where((r) => r.date.isAfter(filter.startDate!.subtract(const Duration(seconds: 1)))).toList();
    }

    if (filter.endDate != null) {
      results = results.where((r) => r.date.isBefore(filter.endDate!.add(const Duration(days: 1)))).toList();
    }

    final totalCount = results.length;
    final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 999);
    final startIndex = ((filter.page - 1) * filter.pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + filter.pageSize).clamp(0, totalCount);

    return PaginatedList<AttendanceRecord>(
      items: results.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<AttendanceRecord> getAttendanceDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockRecords.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('Attendance record not found with ID: $id'),
    );
  }

  @override
  Future<List<AttendanceEvent>> getAttendanceEvents(String recordId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final record = await getAttendanceDetails(recordId);
    return record.events;
  }

  @override
  Future<AttendanceKpiSummary> getAttendanceKpis({DateTime? date}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return AttendanceKpiSummary(
      totalEmployees: 5,
      presentCount: _mockRecords.where((r) => r.status == AttendanceStatus.present).length,
      absentCount: _mockRecords.where((r) => r.status == AttendanceStatus.absent).length,
      lateCount: _mockRecords.where((r) => r.status == AttendanceStatus.late).length,
      earlyDepartureCount: _mockRecords.where((r) => r.status == AttendanceStatus.earlyDeparture).length,
      overtimeCount: _mockRecords.where((r) => r.status == AttendanceStatus.overtime).length,
      offlinePendingCount: _mockRecords.where((r) => r.isOfflinePending).length,
      suspiciousCount: _mockRecords.where((r) => r.securityStatus == SecurityStatus.suspicious || r.isFlagged).length,
    );
  }

  @override
  Future<PaginatedList<AttendanceRecord>> getSuspiciousRecords(int page, int pageSize) async {
    return getAttendanceRecords(AttendanceFilter(
      isSuspicious: true,
      page: page,
      pageSize: pageSize,
    ));
  }

  @override
  Future<PaginatedList<AttendanceRecord>> getOfflineRecords(int page, int pageSize) async {
    return getAttendanceRecords(AttendanceFilter(
      isOfflinePending: true,
      page: page,
      pageSize: pageSize,
    ));
  }

  @override
  Future<void> reviewOfflineRecord(String id, {required bool approve, String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _mockRecords.indexWhere((r) => r.id == id);
    if (index != -1) {
      final existing = _mockRecords[index];
      _mockRecords[index] = existing.copyWith(
        isOfflinePending: false,
        status: approve ? AttendanceStatus.present : AttendanceStatus.absent,
        offlineReviewedAt: DateTime.now(),
        offlineReviewedBy: 'HR Admin (Test)',
        offlineReviewNote: reason,
        events: [
          ...existing.events,
          AttendanceEvent(
            id: 'EVT-${DateTime.now().millisecondsSinceEpoch}',
            eventType: approve ? AttendanceEventType.checkInAccepted : AttendanceEventType.checkInRejected,
            timestamp: DateTime.now(),
            description: approve
                ? 'Offline punch approved by HR Admin (Test)'
                : 'Offline punch rejected by HR Admin (Test). Reason: $reason',
          ),
        ],
      );
    }
  }

  @override
  Future<AttendanceRecord> manualCorrection({
    required String employeeId,
    required DateTime date,
    required AttendanceStatus status,
    required DateTime checkInTime,
    required DateTime checkOutTime,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newRecord = AttendanceRecord(
      id: 'MAN-ATT-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: employeeId,
      employeeName: 'Employee $employeeId (Test)',
      employeeCode: 'CW-$employeeId',
      workplaceName: 'HQ Main Tower',
      date: date,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      status: status,
      securityStatus: SecurityStatus.normal,
      rejectionReason: null,
      events: [
        AttendanceEvent(
          id: 'EVT-${DateTime.now().millisecondsSinceEpoch}',
          eventType: AttendanceEventType.manualCorrection,
          timestamp: DateTime.now(),
          description: 'Manual adjustment submitted by HR Admin. Reason: $reason',
        ),
      ],
    );
    _mockRecords.insert(0, newRecord);
    return newRecord;
  }

  @override
  Future<String> exportAttendanceReport(AttendanceFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'https://reports.cyberwise.internal/downloads/attendance_export_mock.csv';
  }
}
