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
      fallbackMockDatabaseNotifier.state = MockDatabase.seed().copyWith(
        attendance: const [],
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
      status: isOffline
          ? AttendanceStatus.offlinePending
          : AttendanceStatus.success,
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
      status: isOffline
          ? AttendanceStatus.offlinePending
          : AttendanceStatus.success,
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
              ? a.copyWith(isOffline: false, status: AttendanceStatus.success)
              : a,
        )
        .toList();

    _db.state = _db.state.copyWith(attendance: synced);
    await Future.delayed(const Duration(milliseconds: 400));
    return pending.length;
  }

  @override
  Future<void> resetToDefaultMock() async {
    _db.resetAttendance();
  }
}
