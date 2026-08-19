import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/mock/mock_database.dart';
import '../../domain/models/attendance.dart';
import '../../domain/models/attendance_api_contracts.dart';
import '../../domain/models/device_integrity_result.dart';
import '../../domain/models/network_risk_info.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../api/attendance_api.dart';
import '../api/mock_attendance_api.dart';

class MockAttendanceRepository implements AttendanceRepository {
  final Ref? _ref;
  final AttendanceApi? _api;
  final _uuid = const Uuid();

  MockAttendanceRepository([Object? source, AttendanceApi? api])
    : _ref = source is Ref ? source : null,
      _api = api {
    if (_ref == null) {
      fallbackMockDatabaseNotifier.replaceState(
        MockDatabase.seed().copyWith(attendance: const []),
      );
    }
  }

  MockDatabaseNotifier get _db =>
      _ref?.read(mockDatabaseProvider.notifier) ?? fallbackMockDatabaseNotifier;
  MockDatabase get _state =>
      _ref?.read(mockDatabaseProvider) ?? fallbackMockDatabaseNotifier.snapshot;

  AttendanceApi get _apiClient =>
      _api ?? MockAttendanceApi(getEmployee: () => _state.employee);

  @override
  Future<TodayAttendanceSummary> getTodayStatus(String employeeId) async {
    return _state.todaySummary;
  }

  @override
  Future<List<Attendance>> getHistory(String employeeId) async {
    return _state.attendance.where((a) => a.employeeId == employeeId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<AttendanceVerificationResponse> submitAttendanceRequest(
    AttendanceSubmissionRequest request,
  ) async {
    final response = await _apiClient.submitAttendance(request);
    if (response.attendanceRecord != null) {
      _db.addAttendance(response.attendanceRecord!);
    }
    return response;
  }

  @override
  Future<Attendance> checkIn({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double distance,
    double accuracy = 3.0,
    String workLocationId = 'LOC-CAIRO-HQ',
    required bool biometricVerified,
    required bool isOffline,
    DeviceIntegrityResult? integrityResult,
    NetworkRiskInfo? networkRisk,
    String? clientRequestId,
  }) async {
    final reqId = clientRequestId ?? _uuid.v4();
    final submission = AttendanceSubmissionRequest(
      clientRequestId: reqId,
      employeeId: employeeId,
      attendanceType: AttendanceType.checkIn,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      clientTimestamp: DateTime.now(),
      workplaceId: workLocationId,
      distanceFromWorkplace: distance,
      biometricVerified: biometricVerified,
      integrityResult: integrityResult,
      networkRisk: networkRisk,
      isOfflineSubmission: isOffline,
    );

    final response = await submitAttendanceRequest(submission);
    if (response.attendanceRecord != null) {
      return response.attendanceRecord!;
    }

    final now = DateTime.now();
    return Attendance(
      id: _uuid.v4(),
      employeeId: employeeId,
      workLocationId: workLocationId,
      date: DateTime(now.year, now.month, now.day),
      type: AttendanceType.checkIn,
      timestamp: now,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      distanceFromOffice: distance,
      biometricVerified: biometricVerified,
      isOffline: isOffline,
      status: isOffline ? AttendanceStatus.offlinePending : AttendanceStatus.rejectedLocation,
      clientRequestId: reqId,
    );
  }

  @override
  Future<Attendance> checkOut({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double distance,
    double accuracy = 3.0,
    String workLocationId = 'LOC-CAIRO-HQ',
    required bool biometricVerified,
    required bool isOffline,
    DeviceIntegrityResult? integrityResult,
    NetworkRiskInfo? networkRisk,
    String? clientRequestId,
  }) async {
    final reqId = clientRequestId ?? _uuid.v4();
    final submission = AttendanceSubmissionRequest(
      clientRequestId: reqId,
      employeeId: employeeId,
      attendanceType: AttendanceType.checkOut,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      clientTimestamp: DateTime.now(),
      workplaceId: workLocationId,
      distanceFromWorkplace: distance,
      biometricVerified: biometricVerified,
      integrityResult: integrityResult,
      networkRisk: networkRisk,
      isOfflineSubmission: isOffline,
    );

    final response = await submitAttendanceRequest(submission);
    if (response.attendanceRecord != null) {
      return response.attendanceRecord!;
    }

    final now = DateTime.now();
    return Attendance(
      id: _uuid.v4(),
      employeeId: employeeId,
      workLocationId: workLocationId,
      date: DateTime(now.year, now.month, now.day),
      type: AttendanceType.checkOut,
      timestamp: now,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      distanceFromOffice: distance,
      biometricVerified: biometricVerified,
      isOffline: isOffline,
      status: isOffline ? AttendanceStatus.offlinePending : AttendanceStatus.rejectedLocation,
      clientRequestId: reqId,
    );
  }

  @override
  Future<List<Attendance>> getPendingOfflineQueue() async {
    return _state.attendance
        .where((a) => a.isOffline || a.status == AttendanceStatus.offlinePending || a.status == AttendanceStatus.pendingHrVerification)
        .toList();
  }

  @override
  Future<int> syncPendingAttendance() async {
    final pending = await getPendingOfflineQueue();
    if (pending.isEmpty) return 0;

    int syncedCount = 0;
    for (final item in pending) {
      final req = AttendanceSubmissionRequest(
        clientRequestId: item.clientRequestId ?? _uuid.v4(),
        employeeId: item.employeeId,
        attendanceType: item.type,
        latitude: item.latitude,
        longitude: item.longitude,
        accuracy: item.accuracy,
        clientTimestamp: item.timestamp,
        workplaceId: item.workLocationId,
        distanceFromWorkplace: item.distanceFromOffice,
        biometricVerified: item.biometricVerified,
        isOfflineSubmission: false, // Now online
      );

      final response = await _apiClient.syncOfflineAttendance(req);
      if (response.success) {
        syncedCount++;
      }
    }

    final updatedAttendance = _state.attendance
        .map(
          (a) => (a.isOffline || a.status == AttendanceStatus.offlinePending)
              ? a.copyWith(
                  isOffline: false,
                  status: AttendanceStatus.success,
                  syncStatus: AttendanceSyncStatus.synced,
                  updatedAt: DateTime.now(),
                  note: 'تمت المزامنة بنجاح مع الخادم',
                )
              : a,
        )
        .toList();

    _db.replaceAttendance(updatedAttendance);
    return syncedCount;
  }

  @override
  Future<void> resetToDefaultMock() async {
    _db.resetAttendance();
  }
}
