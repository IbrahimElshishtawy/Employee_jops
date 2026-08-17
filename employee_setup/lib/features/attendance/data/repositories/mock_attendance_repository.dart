import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/mock/mock_database.dart';
import '../../domain/models/attendance.dart';
import '../../domain/repositories/attendance_repository.dart';

class MockAttendanceRepository implements AttendanceRepository {
  final Ref _ref;
  final _uuid = const Uuid();

  MockAttendanceRepository(this._ref);

  MockDatabaseNotifier get _db => _ref.read(mockDatabaseProvider.notifier);
  MockDatabase get _state => _ref.read(mockDatabaseProvider);

  @override
  Future<TodayAttendanceSummary> getTodayStatus(String employeeId) async {
    return _state.todaySummary;
  }

  @override
  Future<List<Attendance>> getHistory(String employeeId) async {
    return _state.attendance
        .where((a) => a.employeeId == employeeId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<Attendance> checkIn({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double distance,
    required bool biometricVerified,
    required bool isOffline,
  }) async {
    final record = Attendance(
      id: _uuid.v4(),
      employeeId: employeeId,
      type: AttendanceType.checkIn,
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      distanceFromOffice: distance,
      biometricVerified: biometricVerified,
      isOffline: isOffline,
      status: isOffline ? AttendanceStatus.offlinePending : AttendanceStatus.success,
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
    required bool biometricVerified,
    required bool isOffline,
  }) async {
    final record = Attendance(
      id: _uuid.v4(),
      employeeId: employeeId,
      type: AttendanceType.checkOut,
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      distanceFromOffice: distance,
      biometricVerified: biometricVerified,
      isOffline: isOffline,
      status: isOffline ? AttendanceStatus.offlinePending : AttendanceStatus.success,
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
    // Simulate sync in mock — returns count of synced records
    final pending = _state.attendance.where((a) => a.isOffline).toList();
    await Future.delayed(const Duration(milliseconds: 400));
    return pending.length;
  }

  @override
  Future<void> resetToDefaultMock() async {
    _db.resetAttendance();
  }
}
