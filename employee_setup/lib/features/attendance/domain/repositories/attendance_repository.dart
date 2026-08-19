import '../models/attendance.dart';
import '../models/attendance_api_contracts.dart';
import '../models/device_integrity_result.dart';
import '../models/network_risk_info.dart';

abstract class AttendanceRepository {
  Future<TodayAttendanceSummary> getTodayStatus(String employeeId);

  Future<AttendanceVerificationResponse> submitAttendanceRequest(
    AttendanceSubmissionRequest request,
  );

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
  });

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
  });

  Future<List<Attendance>> getHistory(String employeeId);
  Future<List<Attendance>> getPendingOfflineQueue();
  Future<int> syncPendingAttendance();
  Future<void> resetToDefaultMock();
}
