import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/report_entities.dart';

/// Live Production Reports Repository
class ApiReportsRepository implements ReportsRepository {
  final ApiClient _apiClient;

  ApiReportsRepository(this._apiClient);

  @override
  Future<ReportOverviewSummary> getOverviewSummary(ReportFilter filter) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.reports}/overview',
        queryParams: _buildFilterParams(filter),
        parser: (data) {
          final json = data as Map<String, dynamic>;
          return ReportOverviewSummary(
            totalEmployees: json['totalEmployees'] as int? ?? 0,
            presentCount: json['presentCount'] as int? ?? 0,
            absentCount: json['absentCount'] as int? ?? 0,
            lateCount: json['lateCount'] as int? ?? 0,
            earlyCheckoutCount: json['earlyCheckoutCount'] as int? ?? 0,
            pendingRequestsCount: json['pendingRequestsCount'] as int? ?? 0,
            approvedAdvancesAmount: (json['approvedAdvancesAmount'] as num?)?.toDouble() ?? 0.0,
            totalDeductionsAmount: (json['totalDeductionsAmount'] as num?)?.toDouble() ?? 0.0,
            attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
            punctualityRate: (json['punctualityRate'] as num?)?.toDouble() ?? 0.0,
          );
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<AttendanceDailyTrend>> getAttendanceTrends(ReportFilter filter) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.reports}/attendance/trends',
        queryParams: _buildFilterParams(filter),
        parser: (data) {
          final rawList = data as List<dynamic>? ?? [];
          return rawList.map((e) {
            final json = e as Map<String, dynamic>;
            return AttendanceDailyTrend(
              date: DateTime.parse(json['date'] as String),
              present: json['present'] as int? ?? 0,
              absent: json['absent'] as int? ?? 0,
              late: json['late'] as int? ?? 0,
              earlyCheckout: json['earlyCheckout'] as int? ?? 0,
              attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<DepartmentAttendanceMetric>> getDepartmentBreakdown(ReportFilter filter) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.reports}/attendance/departments',
        queryParams: _buildFilterParams(filter),
        parser: (data) {
          final rawList = data as List<dynamic>? ?? [];
          return rawList.map((e) {
            final json = e as Map<String, dynamic>;
            return DepartmentAttendanceMetric(
              department: json['department'] as String? ?? 'General',
              headcount: json['headcount'] as int? ?? 0,
              presentRate: (json['presentRate'] as num?)?.toDouble() ?? 0.0,
              lateCount: json['lateCount'] as int? ?? 0,
              absenceCount: json['absenceCount'] as int? ?? 0,
            );
          }).toList();
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<LateArrivalReportItem>> getLateArrivalsReport(ReportFilter filter) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.reports}/attendance/late',
        queryParams: _buildFilterParams(filter),
        parser: (data) {
          final rawList = data as List<dynamic>? ?? [];
          return rawList.map((e) {
            final json = e as Map<String, dynamic>;
            return LateArrivalReportItem(
              id: json['id'] as String? ?? '',
              employeeId: json['employeeId'] as String? ?? '',
              employeeName: json['employeeName'] as String? ?? '',
              employeeCode: json['employeeCode'] as String? ?? '',
              department: json['department'] as String? ?? '',
              date: DateTime.parse(json['date'] as String),
              scheduledStartTime: json['scheduledStartTime'] as String? ?? '09:00',
              actualCheckInTime: json['actualCheckInTime'] as String? ?? '09:00',
              lateMinutes: json['lateMinutes'] as int? ?? 0,
              hasApprovedExcuse: json['hasApprovedExcuse'] as bool? ?? false,
            );
          }).toList();
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<WorkforceDistributionMetric>> getWorkforceDistribution() async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.reports}/workforce/distribution',
        parser: (data) {
          final rawList = data as List<dynamic>? ?? [];
          return rawList.map((e) {
            final json = e as Map<String, dynamic>;
            return WorkforceDistributionMetric(
              label: json['label'] as String? ?? '',
              count: json['count'] as int? ?? 0,
              percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<String> exportReport({
    required String reportType,
    required ReportFilter filter,
    required String format,
  }) async {
    try {
      final params = _buildFilterParams(filter);
      params['reportType'] = reportType;
      params['format'] = format.toLowerCase();

      final response = await _apiClient.get(
        ApiEndpoints.attendanceExport,
        queryParams: params,
        parser: (data) => (data as Map<String, dynamic>)['downloadUrl'] as String? ?? '',
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  static Map<String, String> _buildFilterParams(ReportFilter filter) {
    final map = <String, String>{
      'preset': filter.datePreset.name,
    };
    if (filter.startDate != null) map['startDate'] = filter.startDate!.toIso8601String();
    if (filter.endDate != null) map['endDate'] = filter.endDate!.toIso8601String();
    if (filter.department != null) map['department'] = filter.department!;
    if (filter.workplaceId != null) map['workplaceId'] = filter.workplaceId!;
    return map;
  }
}
