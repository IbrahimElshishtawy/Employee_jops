import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/models/employee.dart';
import '../../domain/models/attendance.dart';
import '../../domain/models/attendance_api_contracts.dart';
import '../../domain/models/attendance_state_type.dart';
import 'attendance_api.dart';

class RealAttendanceApi implements AttendanceApi {
  final ApiClient apiClient;
  final Employee Function() getEmployee;

  RealAttendanceApi({
    required this.apiClient,
    required this.getEmployee,
  });

  @override
  Future<AttendanceVerificationResponse> submitAttendance(
    AttendanceSubmissionRequest request,
  ) async {
    final endpoint = request.attendanceType == AttendanceType.checkIn
        ? ApiEndpoints.attendanceCheckIn
        : ApiEndpoints.attendanceCheckOut;

    try {
      final response = await apiClient.post(
        endpoint,
        data: request.toBackendDto(),
      );

      if (response.data is Map<String, dynamic>) {
        return AttendanceVerificationResponse.fromBackendJson(
          response.data as Map<String, dynamic>,
          type: request.attendanceType,
          employeeId: request.employeeId,
        );
      }

      return AttendanceVerificationResponse(
        success: response.success,
        decision: response.success ? AttendanceDecision.approved : AttendanceDecision.rejected,
        rejectionReason: response.success ? RejectionReason.none : RejectionReason.serverInternalError,
        message: response.message ?? 'Attendance processed',
        serverTimestamp: DateTime.now(),
      );
    } on ApiException catch (e) {
      return AttendanceVerificationResponse(
        success: false,
        decision: AttendanceDecision.rejected,
        rejectionReason: e is ConflictException
            ? RejectionReason.duplicateSubmission
            : RejectionReason.serverInternalError,
        message: e.message,
        serverTimestamp: DateTime.now(),
      );
    } catch (e) {
      return AttendanceVerificationResponse(
        success: false,
        decision: AttendanceDecision.rejected,
        rejectionReason: RejectionReason.serverInternalError,
        message: e.toString(),
        serverTimestamp: DateTime.now(),
      );
    }
  }

  @override
  Future<TodayAttendanceSummary> getTodayStatus(String employeeId) async {
    try {
      final response = await apiClient.get(ApiEndpoints.attendanceToday);
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final payload = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;

        Attendance? checkIn;
        Attendance? checkOut;

        if (payload['checkIn'] is Map<String, dynamic>) {
          checkIn = Attendance.fromJson(payload['checkIn'] as Map<String, dynamic>);
        }
        if (payload['checkOut'] is Map<String, dynamic>) {
          checkOut = Attendance.fromJson(payload['checkOut'] as Map<String, dynamic>);
        }

        return TodayAttendanceSummary(
          checkIn: checkIn,
          checkOut: checkOut,
        );
      }
    } catch (_) {}

    return const TodayAttendanceSummary();
  }

  @override
  Future<AttendanceVerificationResponse> syncOfflineAttendance(
    AttendanceSubmissionRequest request,
  ) {
    return submitAttendance(request);
  }
}
