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
      if (filter.securityStatus != null) queryParams['securityStatus'] = filter.securityStatus!.key;
      if (filter.workplaceId != null) queryParams['workplaceId'] = filter.workplaceId!;
      if (filter.department != null) queryParams['department'] = filter.department!;
      if (filter.isOfflinePending != null) queryParams['isOfflinePending'] = filter.isOfflinePending.toString();
      if (filter.isSuspicious != null) queryParams['isSuspicious'] = filter.isSuspicious.toString();
      if (filter.startDate != null) queryParams['startDate'] = filter.startDate!.toIso8601String();
      if (filter.endDate != null) queryParams['endDate'] = filter.endDate!.toIso8601String();

      final response = await _apiClient.get(
        ApiEndpoints.attendanceHistory,
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) => _mapRecord(e as Map<String, dynamic>)).toList();

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
  Future<AttendanceRecord> getAttendanceDetails(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.attendanceHistory}/$id',
        parser: (data) => _mapRecord(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<AttendanceEvent>> getAttendanceEvents(String recordId) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.attendanceHistory}/$recordId/events',
        parser: (data) {
          final list = (data as List<dynamic>?) ?? [];
          return list.map((e) {
            final m = e as Map<String, dynamic>;
            return AttendanceEvent(
              id: m['id'] as String,
              eventType: AttendanceEventType.fromKey(m['eventType'] as String?),
              timestamp: DateTime.parse(m['timestamp'] as String),
              description: m['description'] as String? ?? '',
              metadata: m['metadata'] as Map<String, dynamic>?,
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
  Future<AttendanceKpiSummary> getAttendanceKpis({DateTime? date}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.attendanceToday,
        queryParams: date != null ? {'date': date.toIso8601String()} : null,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          return AttendanceKpiSummary(
            totalEmployees: json['totalEmployees'] as int? ?? 0,
            presentCount: json['presentCount'] as int? ?? 0,
            absentCount: json['absentCount'] as int? ?? 0,
            lateCount: json['lateCount'] as int? ?? 0,
            earlyDepartureCount: json['earlyDepartureCount'] as int? ?? 0,
            overtimeCount: json['overtimeCount'] as int? ?? 0,
            offlinePendingCount: json['offlinePendingCount'] as int? ?? 0,
            suspiciousCount: json['suspiciousCount'] as int? ?? 0,
          );
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<PaginatedList<AttendanceRecord>> getSuspiciousRecords(int page, int pageSize) {
    return getAttendanceRecords(AttendanceFilter(
      isSuspicious: true,
      page: page,
      pageSize: pageSize,
    ));
  }

  @override
  Future<PaginatedList<AttendanceRecord>> getOfflineRecords(int page, int pageSize) {
    return getAttendanceRecords(AttendanceFilter(
      isOfflinePending: true,
      page: page,
      pageSize: pageSize,
    ));
  }

  @override
  Future<void> reviewOfflineRecord(String id, {required bool approve, String? reason}) async {
    try {
      await _apiClient.post(
        '${ApiEndpoints.attendanceHistory}/$id/offline-review',
        body: {
          'approve': approve,
          if (reason != null) 'reason': reason,
        },
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<AttendanceRecord> manualCorrection({
    required String employeeId,
    required DateTime date,
    required AttendanceStatus status,
    required DateTime checkInTime,
    required DateTime checkOutTime,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.attendanceHistory}/manual',
        body: {
          'employeeId': employeeId,
          'date': date.toIso8601String(),
          'status': status.key,
          'checkInTime': checkInTime.toIso8601String(),
          'checkOutTime': checkOutTime.toIso8601String(),
          'reason': reason,
        },
        parser: (data) => _mapRecord(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<String> exportAttendanceReport(AttendanceFilter filter) async {
    try {
      final queryParams = <String, String>{};
      if (filter.startDate != null) queryParams['startDate'] = filter.startDate!.toIso8601String();
      if (filter.endDate != null) queryParams['endDate'] = filter.endDate!.toIso8601String();
      if (filter.status != null) queryParams['status'] = filter.status!.key;
      if (filter.workplaceId != null) queryParams['workplaceId'] = filter.workplaceId!;

      final response = await _apiClient.post(
        ApiEndpoints.attendanceExport,
        queryParams: queryParams,
        parser: (data) => (data as Map<String, dynamic>)['downloadUrl'] as String,
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  static AttendanceRecord _mapRecord(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String? ?? '',
      employeeCode: map['employeeCode'] as String? ?? '',
      department: map['department'] as String? ?? 'General',
      workplaceId: map['workplaceId'] as String? ?? 'WP-001',
      workplaceName: map['workplaceName'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      checkInTime: map['checkInTime'] != null ? DateTime.parse(map['checkInTime'] as String) : null,
      checkOutTime: map['checkOutTime'] != null ? DateTime.parse(map['checkOutTime'] as String) : null,
      status: AttendanceStatus.fromKey(map['status'] as String?),
      lateMinutes: map['lateMinutes'] as int?,
      overtimeMinutes: map['overtimeMinutes'] as int?,
      rejectionReason: map['rejectionReason'] as String?,
      isFlagged: map['isFlagged'] as bool? ?? false,
      checkInLat: (map['checkInLat'] as num?)?.toDouble(),
      checkInLng: (map['checkInLng'] as num?)?.toDouble(),
      checkInAccuracy: (map['checkInAccuracy'] as num?)?.toDouble(),
      checkInDistanceMeters: (map['checkInDistanceMeters'] as num?)?.toDouble(),
      checkInGeofenceValid: map['checkInGeofenceValid'] as bool?,
      checkOutLat: (map['checkOutLat'] as num?)?.toDouble(),
      checkOutLng: (map['checkOutLng'] as num?)?.toDouble(),
      checkOutAccuracy: (map['checkOutAccuracy'] as num?)?.toDouble(),
      checkOutDistanceMeters: (map['checkOutDistanceMeters'] as num?)?.toDouble(),
      checkOutGeofenceValid: map['checkOutGeofenceValid'] as bool?,
      securityStatus: SecurityStatus.fromKey(map['securityStatus'] as String?),
      securitySignals: (map['securitySignals'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
      deviceModel: map['deviceModel'] as String?,
      deviceOs: map['deviceOs'] as String?,
      isOfflinePending: map['isOfflinePending'] as bool? ?? false,
      offlineRecordedAt: map['offlineRecordedAt'] != null ? DateTime.parse(map['offlineRecordedAt'] as String) : null,
      offlineReviewedAt: map['offlineReviewedAt'] != null ? DateTime.parse(map['offlineReviewedAt'] as String) : null,
      offlineReviewedBy: map['offlineReviewedBy'] as String?,
      offlineReviewNote: map['offlineReviewNote'] as String?,
      scheduleName: map['scheduleName'] as String?,
      shiftStart: map['shiftStart'] as String?,
      shiftEnd: map['shiftEnd'] as String?,
      gracePeriodMinutes: map['gracePeriodMinutes'] as int?,
      events: (map['events'] as List<dynamic>?)?.map((e) {
            final m = e as Map<String, dynamic>;
            return AttendanceEvent(
              id: m['id'] as String,
              eventType: AttendanceEventType.fromKey(m['eventType'] as String?),
              timestamp: DateTime.parse(m['timestamp'] as String),
              description: m['description'] as String? ?? '',
            );
          }).toList() ??
          [],
    );
  }
}
