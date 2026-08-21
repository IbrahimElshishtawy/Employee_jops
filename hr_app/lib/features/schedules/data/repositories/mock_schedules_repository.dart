import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/schedule_entity.dart';

/// Mock Work Schedules Repository with safe test records
class MockSchedulesRepository implements SchedulesRepository {
  final List<WorkScheduleEntity> _mockSchedules = [
    WorkScheduleEntity(
      id: 'SCH-001',
      name: 'Standard Core Business Hours',
      description: 'Standard 8-hour core shift for general headquarters and administration',
      startTime: '09:00',
      endTime: '17:00',
      workingDays: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'],
      gracePeriodMinutes: 15,
      assignedCount: 42,
      isActive: true,
      department: 'Administration',
      workplaceName: 'CyberWise HQ Cairo',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    ),
    WorkScheduleEntity(
      id: 'SCH-002',
      name: 'Early Morning Operations Shift',
      description: 'Early shift for data center maintenance and operations monitoring',
      startTime: '08:00',
      endTime: '16:00',
      workingDays: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'],
      gracePeriodMinutes: 10,
      assignedCount: 18,
      isActive: true,
      department: 'Operations',
      workplaceName: 'CyberWise Alexandria Hub',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    WorkScheduleEntity(
      id: 'SCH-003',
      name: 'Flexible Engineering Hours',
      description: 'Flexible technical team shift with expanded grace period',
      startTime: '10:00',
      endTime: '18:00',
      workingDays: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'],
      gracePeriodMinutes: 30,
      assignedCount: 25,
      isActive: true,
      department: 'Engineering',
      workplaceName: 'CyberWise HQ Cairo',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    WorkScheduleEntity(
      id: 'SCH-004',
      name: 'Weekend Support & SOC Shift',
      description: 'Rotational 24/7 weekend coverage shift for security monitoring',
      startTime: '12:00',
      endTime: '20:00',
      workingDays: const ['Fri', 'Sat'],
      gracePeriodMinutes: 10,
      assignedCount: 6,
      isActive: false,
      department: 'Information Technology',
      workplaceName: 'Smart Village Data Center',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  @override
  Future<PaginatedList<WorkScheduleEntity>> getSchedules(ScheduleFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var results = List<WorkScheduleEntity>.from(_mockSchedules);

    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = filter.searchQuery!.trim().toLowerCase();
      results = results.where((s) =>
          s.name.toLowerCase().contains(q) ||
          (s.description?.toLowerCase().contains(q) ?? false) ||
          (s.department?.toLowerCase().contains(q) ?? false) ||
          (s.workplaceName?.toLowerCase().contains(q) ?? false)).toList();
    }

    if (filter.isActive != null) {
      results = results.where((s) => s.isActive == filter.isActive).toList();
    }

    if (filter.workingDay != null && filter.workingDay!.isNotEmpty) {
      results = results.where((s) => s.workingDays.contains(filter.workingDay)).toList();
    }

    if (filter.department != null && filter.department!.isNotEmpty) {
      results = results.where((s) => s.department?.toLowerCase() == filter.department!.toLowerCase()).toList();
    }

    final totalCount = results.length;
    final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 999);
    final startIndex = ((filter.page - 1) * filter.pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + filter.pageSize).clamp(0, totalCount);

    return PaginatedList<WorkScheduleEntity>(
      items: results.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<WorkScheduleEntity> getScheduleById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockSchedules.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('Schedule not found with ID: $id'),
    );
  }

  @override
  Future<ScheduleKpiSummary> getScheduleKpis() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final activeCount = _mockSchedules.where((s) => s.isActive).length;
    final inactiveCount = _mockSchedules.where((s) => !s.isActive).length;
    final totalAssigned = _mockSchedules.fold<int>(0, (sum, s) => sum + s.assignedCount);

    return ScheduleKpiSummary(
      totalCount: _mockSchedules.length,
      activeCount: activeCount,
      inactiveCount: inactiveCount,
      assignedEmployeesCount: totalAssigned,
      unassignedEmployeesCount: 4, // Headcount without schedule
    );
  }

  @override
  Future<WorkScheduleEntity> createSchedule(WorkScheduleEntity schedule) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _mockSchedules.insert(0, schedule);
    return schedule;
  }

  @override
  Future<WorkScheduleEntity> updateSchedule(WorkScheduleEntity schedule) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _mockSchedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _mockSchedules[index] = schedule.copyWith(updatedAt: DateTime.now());
      return _mockSchedules[index];
    }
    throw Exception('Schedule not found for update');
  }

  @override
  Future<void> toggleScheduleStatus(String id, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockSchedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      _mockSchedules[index] = _mockSchedules[index].copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
    }
  }
}
