import '../../domain/models/attendance.dart';
import '../../domain/models/attendance_api_contracts.dart';

/// AttendanceApi defines the REST API contract for enterprise mobile attendance.
/// Endpoints:
/// - POST /attendance/check-in
/// - POST /attendance/check-out
/// - GET  /attendance/today
/// - GET  /attendance/status
/// - POST /attendance/sync-offline
abstract class AttendanceApi {
  /// Submits an attendance action (check-in or check-out).
  Future<AttendanceVerificationResponse> submitAttendance(
    AttendanceSubmissionRequest request,
  );

  /// Fetches today's attendance summary for the given employee.
  Future<TodayAttendanceSummary> getTodayStatus(String employeeId);

  /// Synchronizes an offline captured attendance record to the server for HR verification.
  Future<AttendanceVerificationResponse> syncOfflineAttendance(
    AttendanceSubmissionRequest request,
  );
}
