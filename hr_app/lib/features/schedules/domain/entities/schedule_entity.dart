import '../../../employees/domain/entities/employee_entity.dart';

/// Aggregated KPI summary for work schedules
class ScheduleKpiSummary {
  final int totalCount;
  final int activeCount;
  final int inactiveCount;
  final int assignedEmployeesCount;
  final int unassignedEmployeesCount;

  const ScheduleKpiSummary({
    required this.totalCount,
    required this.activeCount,
    required this.inactiveCount,
    required this.assignedEmployeesCount,
    required this.unassignedEmployeesCount,
  });
}

/// Work Schedule Entity defining shift times and grace periods
class WorkScheduleEntity {
  final String id;
  final String name;
  final String? description;
  final String startTime; // e.g. "08:00"
  final String endTime;   // e.g. "16:00"
  final List<String> workingDays; // e.g. ["Sun", "Mon", "Tue", "Wed", "Thu"]
  final int gracePeriodMinutes;
  final int assignedCount;
  final bool isActive;
  final String? department;
  final String? workplaceName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorkScheduleEntity({
    required this.id,
    required this.name,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.workingDays,
    this.gracePeriodMinutes = 15,
    this.assignedCount = 0,
    this.isActive = true,
    this.department,
    this.workplaceName,
    this.createdAt,
    this.updatedAt,
  });

  WorkScheduleEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? startTime,
    String? endTime,
    List<String>? workingDays,
    int? gracePeriodMinutes,
    int? assignedCount,
    bool? isActive,
    String? department,
    String? workplaceName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkScheduleEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      workingDays: workingDays ?? this.workingDays,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      assignedCount: assignedCount ?? this.assignedCount,
      isActive: isActive ?? this.isActive,
      department: department ?? this.department,
      workplaceName: workplaceName ?? this.workplaceName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ScheduleFilter {
  final String? searchQuery;
  final bool? isActive;
  final String? workingDay;
  final String? department;
  final int page;
  final int pageSize;

  const ScheduleFilter({
    this.searchQuery,
    this.isActive,
    this.workingDay,
    this.department,
    this.page = 1,
    this.pageSize = 10,
  });
}

abstract class SchedulesRepository {
  Future<PaginatedList<WorkScheduleEntity>> getSchedules(ScheduleFilter filter);
  Future<WorkScheduleEntity> getScheduleById(String id);
  Future<ScheduleKpiSummary> getScheduleKpis();
  Future<WorkScheduleEntity> createSchedule(WorkScheduleEntity schedule);
  Future<WorkScheduleEntity> updateSchedule(WorkScheduleEntity schedule);
  Future<void> toggleScheduleStatus(String id, bool isActive);
}
