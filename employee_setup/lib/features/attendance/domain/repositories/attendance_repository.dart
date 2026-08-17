import '../models/attendance.dart';

abstract class AttendanceRepository {
  Future<TodayAttendanceSummary> getTodayStatus(String employeeId);
  Future<Attendance> checkIn({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double distance,
    required bool biometricVerified,
    required bool isOffline,
  });
  Future<Attendance> checkOut({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double distance,
    required bool biometricVerified,
    required bool isOffline,
  });
  Future<List<Attendance>> getHistory(String employeeId);
  Future<List<Attendance>> getPendingOfflineQueue();
  Future<int> syncPendingAttendance();
  Future<void> resetToDefaultMock();
}
