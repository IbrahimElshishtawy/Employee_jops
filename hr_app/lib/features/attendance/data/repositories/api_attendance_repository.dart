import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/attendance_record.dart';

/// Live Production Attendance Repository
class ApiAttendanceRepository implements AttendanceRepository {
  final ApiClient _apiClient;

  ApiAttendanceRepository(this._apiClient);

  @override
  Future<PaginatedList<AttendanceRecord>> getAttendanceRecords(AttendanceFilter filter) async {
    try {
      final queryParams = <String, String>{
        'page': filter.page.toString(),
        'pageSize': filter.pageSize.toString(),
      };
      if (filter.searchQuery != null) queryParams['q'] = filter.searchQuery!;
      if (filter.status != null) queryParams['status'] = filter.status!.key;
      if (filter.workplaceId != null) queryParams['workplaceId'] = filter.workplaceId!;
      if (filter.startDate != null) queryParams['startDate'] = filter.startDate!.toIso8601String();
      if (filter.endDate != null) queryParams['endDate'] = filter.endDate!.toIso8601String();

      final response = await _apiClient.get(
        ApiEndpoints.attendanceHistory,
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) {
            final map = e as Map<String, dynamic>;
            return AttendanceRecord(
              id: map['id'] as String,
              employeeId: map['employeeId'] as String,
              employeeName: map['employeeName'] as String? ?? '',
              employeeCode: map['employeeCode'] as String? ?? '',
              workplaceName: map['workplaceName'] as String? ?? '',
              date: DateTime.parse(map['date'] as String),
              checkInTime: map['checkInTime'] != null ? DateTime.parse(map['checkInTime'] as String) : null,
              checkOutTime: map['checkOutTime'] != null ? DateTime.parse(map['checkOutTime'] as String) : null,
              status: AttendanceStatus.fromKey(map['status'] as String?),
              lateMinutes: map['lateMinutes'] as int?,
              overtimeMinutes: map['overtimeMinutes'] as int?,
              rejectionReason: map['rejectionReason'] as String?,
              isFlagged: map['isFlagged'] as bool? ?? false,
            );
          }).toList();

          return PaginatedList<AttendanceRecord>(
            items: items,
            totalCount: json['totalCount'] as int? ?? items.length,
            page: json['page'] as int? ?? filter.page,
            pageSize: json['pageSize'] as int? ?? filter.pageSize,
            totalPages: json['totalPages'] as int? ?? 1,
          );
        },
      );

      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<AttendanceRecord>> getTodayAttendance() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.attendanceToday,
        parser: (data) {
          final list = data as List<dynamic>;
          return list.map((e) {
            final map = e as Map<String, dynamic>;
            return AttendanceRecord(
              id: map['id'] as String,
              employeeId: map['employeeId'] as String,
              employeeName: map['employeeName'] as String? ?? '',
              employeeCode: map['employeeCode'] as String? ?? '',
              workplaceName: map['workplaceName'] as String? ?? '',
              date: DateTime.parse(map['date'] as String),
              checkInTime: map['checkInTime'] != null ? DateTime.parse(map['checkInTime'] as String) : null,
              checkOutTime: map['checkOutTime'] != null ? DateTime.parse(map['checkOutTime'] as String) : null,
              status: AttendanceStatus.fromKey(map['status'] as String?),
              lateMinutes: map['lateMinutes'] as int?,
              overtimeMinutes: map['overtimeMinutes'] as int?,
            );
          }).toList();
        },
      );
      return response.data ?? [];
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<String> exportAttendanceReport(AttendanceFilter filter) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.attendanceExport,
        parser: (data) => (data as Map<String, dynamic>)['downloadUrl'] as String,
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }
}
