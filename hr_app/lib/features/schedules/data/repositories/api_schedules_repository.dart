import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/schedule_entity.dart';

/// Live Production Schedules Repository
class ApiSchedulesRepository implements SchedulesRepository {
  final ApiClient _apiClient;

  ApiSchedulesRepository(this._apiClient);

  @override
  Future<PaginatedList<WorkScheduleEntity>> getSchedules(ScheduleFilter filter) async {
    try {
      final queryParams = <String, String>{
        'page': filter.page.toString(),
        'pageSize': filter.pageSize.toString(),
      };
      if (filter.searchQuery != null) queryParams['q'] = filter.searchQuery!;
      if (filter.isActive != null) queryParams['isActive'] = filter.isActive.toString();
      if (filter.workingDay != null) queryParams['workingDay'] = filter.workingDay!;
      if (filter.department != null) queryParams['department'] = filter.department!;

      final response = await _apiClient.get(
        ApiEndpoints.schedules,
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) => _mapSchedule(e as Map<String, dynamic>)).toList();

          return PaginatedList<WorkScheduleEntity>(
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
  Future<WorkScheduleEntity> getScheduleById(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.schedules}/$id',
        parser: (data) => _mapSchedule(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<ScheduleKpiSummary> getScheduleKpis() async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.schedules}/kpis',
        parser: (data) {
          final json = data as Map<String, dynamic>;
          return ScheduleKpiSummary(
            totalCount: json['totalCount'] as int? ?? 0,
            activeCount: json['activeCount'] as int? ?? 0,
            inactiveCount: json['inactiveCount'] as int? ?? 0,
            assignedEmployeesCount: json['assignedEmployeesCount'] as int? ?? 0,
            unassignedEmployeesCount: json['unassignedEmployeesCount'] as int? ?? 0,
          );
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<WorkScheduleEntity> createSchedule(WorkScheduleEntity schedule) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.schedules,
        body: {
          'name': schedule.name,
          'description': schedule.description,
          'startTime': schedule.startTime,
          'endTime': schedule.endTime,
          'workingDays': schedule.workingDays,
          'gracePeriodMinutes': schedule.gracePeriodMinutes,
          'isActive': schedule.isActive,
          'department': schedule.department,
        },
        parser: (data) => _mapSchedule(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<WorkScheduleEntity> updateSchedule(WorkScheduleEntity schedule) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.schedules}/${schedule.id}',
        body: {
          'name': schedule.name,
          'description': schedule.description,
          'startTime': schedule.startTime,
          'endTime': schedule.endTime,
          'workingDays': schedule.workingDays,
          'gracePeriodMinutes': schedule.gracePeriodMinutes,
          'isActive': schedule.isActive,
          'department': schedule.department,
        },
        parser: (data) => _mapSchedule(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> toggleScheduleStatus(String id, bool isActive) async {
    try {
      await _apiClient.patch(
        '${ApiEndpoints.schedules}/$id/status',
        body: {'isActive': isActive},
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  static WorkScheduleEntity _mapSchedule(Map<String, dynamic> map) {
    final rawDays = (map['workingDays'] as List<dynamic>?) ?? [];
    return WorkScheduleEntity(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      startTime: map['startTime'] as String? ?? '09:00',
      endTime: map['endTime'] as String? ?? '17:00',
      workingDays: rawDays.map((d) => d.toString()).toList(),
      gracePeriodMinutes: map['gracePeriodMinutes'] as int? ?? 15,
      assignedCount: map['assignedCount'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      department: map['department'] as String?,
      workplaceName: map['workplaceName'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }
}
