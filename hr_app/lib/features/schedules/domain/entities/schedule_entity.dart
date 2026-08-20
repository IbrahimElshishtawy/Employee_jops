import '../../../employees/domain/entities/employee_entity.dart';

/// Work Schedule Entity defining shift times and grace periods
class WorkScheduleEntity {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final List<String> workingDays;
  final int gracePeriodMinutes;
  final int assignedCount;
  final bool isActive;

  const WorkScheduleEntity({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.workingDays,
    required this.gracePeriodMinutes,
    required this.assignedCount,
    required this.isActive,
  });
}

abstract class SchedulesRepository {
  Future<PaginatedList<WorkScheduleEntity>> getSchedules(int page, int pageSize);
}

class MockSchedulesRepository implements SchedulesRepository {
  final List<WorkScheduleEntity> _mockSchedules = [
    const WorkScheduleEntity(
      id: 'SCH-001',
      name: 'Standard Core Business Hours',
      startTime: '09:00',
      endTime: '17:00',
      workingDays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'],
      gracePeriodMinutes: 15,
      assignedCount: 38,
      isActive: true,
    ),
    const WorkScheduleEntity(
      id: 'SCH-002',
      name: 'Early Morning Operations Shift',
      startTime: '08:00',
      endTime: '16:00',
      workingDays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'],
      gracePeriodMinutes: 10,
      assignedCount: 10,
      isActive: true,
    ),
  ];

  @override
  Future<PaginatedList<WorkScheduleEntity>> getSchedules(int page, int pageSize) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return PaginatedList<WorkScheduleEntity>(
      items: _mockSchedules,
      totalCount: _mockSchedules.length,
      page: page,
      pageSize: pageSize,
      totalPages: 1,
    );
  }
}
