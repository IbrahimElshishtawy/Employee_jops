import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/mock/mock_database.dart';
import '../../domain/models/attendance.dart';
import '../../domain/repositories/attendance_repository.dart';

class MockAttendanceRepository implements AttendanceRepository {
  final Ref? _ref;
  final _uuid = const Uuid();

  MockAttendanceRepository([Object? source])
    : _ref = source is Ref ? source : null {
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
  Future<Attendance> checkIn({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double distance,
    double accuracy = 3.0,
    String workLocationId = 'LOC-CAIRO-HQ',
    required bool biometricVerified,
    required bool isOffline,
  }) async {
    final now = DateTime.now();
    final record = Attendance(
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
      method: isOffline ? AttendanceMethod.offlineBiometric : AttendanceMethod.biometric,
      syncStatus: isOffline ? AttendanceSyncStatus.pending : AttendanceSyncStatus.synced,
      status: isOffline
          ? AttendanceStatus.offlinePending
          : AttendanceStatus.success,
      createdAt: now,
      updatedAt: now,
    );
    _db.addAttendance(record);
    return record;
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
  }) async {
    final now = DateTime.now();
    final record = Attendance(
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
      method: isOffline ? AttendanceMethod.offlineBiometric : AttendanceMethod.biometric,
      syncStatus: isOffline ? AttendanceSyncStatus.pending : AttendanceSyncStatus.synced,
      status: isOffline
          ? AttendanceStatus.offlinePending
          : AttendanceStatus.success,
      createdAt: now,
      updatedAt: now,
    );
    _db.addAttendance(record);
    return record;
  }

  @override
  Future<List<Attendance>> getPendingOfflineQueue() async {
    return _state.attendance.where((a) => a.isOffline).toList();
  }

  @override
  Future<int> syncPendingAttendance() async {
    final pending = _state.attendance.where((a) => a.isOffline).toList();
    if (pending.isEmpty) return 0;

    final synced = _state.attendance
        .map(
          (a) => a.isOffline
              ? a.copyWith(
                  isOffline: false,
                  status: AttendanceStatus.success,
                  syncStatus: AttendanceSyncStatus.synced,
                  updatedAt: DateTime.now(),
                )
              : a,
        )
        .toList();

    _db.replaceAttendance(synced);
    await Future.delayed(const Duration(milliseconds: 400));
    return pending.length;
  }

  @override
  Future<void> resetToDefaultMock() async {
    _db.resetAttendance();
  }
}
