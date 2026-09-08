import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/attendance.dart';
import '../../domain/models/attendance_api_contracts.dart';
import '../../domain/models/work_schedule.dart';

class AttendanceRemoteDataSource {
  final ApiClient apiClient;

  const AttendanceRemoteDataSource(this.apiClient);

  /// Submits check-in to backend API (POST /api/v1/attendance/check-in)
  Future<AttendanceVerificationResponse> checkIn(
    AttendanceSubmissionRequest request,
  ) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.attendanceCheckIn,
        data: request.toBackendDto(),
      );

      if (response.data is Map<String, dynamic>) {
        return AttendanceVerificationResponse.fromBackendJson(
          response.data as Map<String, dynamic>,
          type: AttendanceType.checkIn,
          employeeId: request.employeeId,
        );
      }

      return AttendanceVerificationResponse(
        success: response.success,
        decision: response.success ? AttendanceDecision.approved : AttendanceDecision.rejected,
        rejectionReason: response.success ? RejectionReason.none : RejectionReason.serverInternalError,
        message: response.message ?? 'Check-in processed',
        serverTimestamp: DateTime.now(),
      );
    } on ApiException catch (e) {
      SecureLogger.error('AttendanceRemoteDataSource', 'Check-in API error', e);
      return AttendanceVerificationResponse(
        success: false,
        decision: AttendanceDecision.rejected,
        rejectionReason: e is ConflictException
            ? RejectionReason.duplicateSubmission
            : RejectionReason.serverInternalError,
        message: e.message,
        serverTimestamp: DateTime.now(),
      );
    }
  }

  /// Submits check-out to backend API (POST /api/v1/attendance/check-out)
  Future<AttendanceVerificationResponse> checkOut(
    AttendanceSubmissionRequest request,
  ) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.attendanceCheckOut,
        data: request.toBackendDto(),
      );

      if (response.data is Map<String, dynamic>) {
        return AttendanceVerificationResponse.fromBackendJson(
          response.data as Map<String, dynamic>,
          type: AttendanceType.checkOut,
          employeeId: request.employeeId,
        );
      }

      return AttendanceVerificationResponse(
        success: response.success,
        decision: response.success ? AttendanceDecision.approved : AttendanceDecision.rejected,
        rejectionReason: response.success ? RejectionReason.none : RejectionReason.serverInternalError,
        message: response.message ?? 'Check-out processed',
        serverTimestamp: DateTime.now(),
      );
    } on ApiException catch (e) {
      SecureLogger.error('AttendanceRemoteDataSource', 'Check-out API error', e);
      return AttendanceVerificationResponse(
        success: false,
        decision: AttendanceDecision.rejected,
        rejectionReason: RejectionReason.serverInternalError,
        message: e.message,
        serverTimestamp: DateTime.now(),
      );
    }
  }

  /// Fetches today's attendance status from GET /api/v1/attendance/today
  Future<Attendance?> getTodayAttendance() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.attendanceToday,
        fromData: (data) {
          if (data is Map<String, dynamic> && data.isNotEmpty) {
            return Attendance.fromJson(data);
          }
          return null;
        },
      );
      return response.data;
    } on ApiException catch (e) {
      SecureLogger.error('AttendanceRemoteDataSource', 'Today attendance error', e);
      return null;
    }
  }

  /// Fetches attendance history records from GET /api/v1/attendance/me
  Future<List<Attendance>> getAttendanceHistory({int? month, int? year}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final response = await apiClient.get(
        ApiEndpoints.attendanceMe,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromData: (data) {
          if (data is List) {
            return data.map((e) => Attendance.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <Attendance>[];
        },
      );
      return response.data ?? [];
    } on ApiException catch (e) {
      SecureLogger.error('AttendanceRemoteDataSource', 'Attendance history error', e);
      return [];
    }
  }

  /// Fetches workplace coordinates and geofence radius from GET /api/v1/employees/me/workplace
  Future<Map<String, dynamic>?> getWorkplaceGeofence() async {
    try {
      final response = await apiClient.get(ApiEndpoints.workplaceMe);
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
      }
      return null;
    } catch (e) {
      SecureLogger.error('AttendanceRemoteDataSource', 'Workplace fetch error', e);
      return null;
    }
  }

  /// Fetches work shift schedule from GET /api/v1/employees/me/schedule
  Future<WorkSchedule?> getWorkSchedule() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.scheduleMe,
        fromData: (data) {
          if (data is Map<String, dynamic>) {
            return WorkSchedule.fromJson(data);
          }
          return null;
        },
      );
      return response.data;
    } catch (e) {
      SecureLogger.error('AttendanceRemoteDataSource', 'Schedule fetch error', e);
      return null;
    }
  }
}
