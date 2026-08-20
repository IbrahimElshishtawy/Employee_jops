import '../../domain/entities/employee_entity.dart';

/// Mock Employee Repository with strictly safe test data
class MockEmployeeRepository implements EmployeeRepository {
  final List<EmployeeEntity> _mockEmployees = [
    EmployeeEntity(
      id: 'TEST-EMP-001',
      employeeCode: 'CW-001',
      fullName: 'Alex Vance (Test)',
      email: 'alex.vance@example.test',
      phone: '+201000000001',
      department: 'Engineering',
      jobTitle: 'Senior Systems Engineer',
      workplaceId: 'WP-001',
      workplaceName: 'HQ Main Tower',
      scheduleId: 'SCH-001',
      scheduleName: 'Standard Core (09:00 - 17:00)',
      managerName: 'Sarah Jenkins (Test)',
      status: EmployeeStatus.active,
      joinedDate: DateTime(2023, 1, 15),
    ),
    EmployeeEntity(
      id: 'TEST-EMP-002',
      employeeCode: 'CW-002',
      fullName: 'Jordan Miller (Test)',
      email: 'jordan.miller@example.test',
      phone: '+201000000002',
      department: 'Human Resources',
      jobTitle: 'HR Specialist',
      workplaceId: 'WP-001',
      workplaceName: 'HQ Main Tower',
      scheduleId: 'SCH-001',
      scheduleName: 'Standard Core (09:00 - 17:00)',
      managerName: 'Sarah Jenkins (Test)',
      status: EmployeeStatus.active,
      joinedDate: DateTime(2023, 3, 1),
    ),
    EmployeeEntity(
      id: 'TEST-EMP-003',
      employeeCode: 'CW-003',
      fullName: 'Taylor Morgan (Test)',
      email: 'taylor.morgan@example.test',
      phone: '+201000000003',
      department: 'Operations',
      jobTitle: 'Operations Coordinator',
      workplaceId: 'WP-002',
      workplaceName: 'Tech Hub Branch',
      scheduleId: 'SCH-002',
      scheduleName: 'Morning Shift (08:00 - 16:00)',
      managerName: 'Sarah Jenkins (Test)',
      status: EmployeeStatus.suspended,
      joinedDate: DateTime(2023, 6, 20),
    ),
    EmployeeEntity(
      id: 'TEST-EMP-004',
      employeeCode: 'CW-004',
      fullName: 'Samira Khan (Test)',
      email: 'samira.khan@example.test',
      phone: '+201000000004',
      department: 'Finance',
      jobTitle: 'Financial Analyst',
      workplaceId: 'WP-001',
      workplaceName: 'HQ Main Tower',
      scheduleId: 'SCH-001',
      scheduleName: 'Standard Core (09:00 - 17:00)',
      managerName: 'Sarah Jenkins (Test)',
      status: EmployeeStatus.active,
      joinedDate: DateTime(2023, 9, 10),
    ),
    EmployeeEntity(
      id: 'TEST-EMP-005',
      employeeCode: 'CW-005',
      fullName: 'Casey Davis (Test)',
      email: 'casey.davis@example.test',
      phone: '+201000000005',
      department: 'Marketing',
      jobTitle: 'Content Strategist',
      workplaceId: 'WP-002',
      workplaceName: 'Tech Hub Branch',
      scheduleId: 'SCH-001',
      scheduleName: 'Standard Core (09:00 - 17:00)',
      managerName: 'Sarah Jenkins (Test)',
      status: EmployeeStatus.deactivated,
      joinedDate: DateTime(2022, 11, 5),
    ),
  ];

  @override
  Future<PaginatedList<EmployeeEntity>> getEmployees(EmployeeFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var results = List<EmployeeEntity>.from(_mockEmployees);

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      results = results.where((e) =>
          e.fullName.toLowerCase().contains(q) ||
          e.email.toLowerCase().contains(q) ||
          e.employeeCode.toLowerCase().contains(q) ||
          e.department.toLowerCase().contains(q)).toList();
    }

    if (filter.status != null) {
      results = results.where((e) => e.status == filter.status).toList();
    }

    final totalCount = results.length;
    final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 999);
    final startIndex = ((filter.page - 1) * filter.pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + filter.pageSize).clamp(0, totalCount);
    final pageItems = results.sublist(startIndex, endIndex);

    return PaginatedList<EmployeeEntity>(
      items: pageItems,
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<EmployeeEntity> getEmployeeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockEmployees.firstWhere((e) => e.id == id);
  }

  @override
  Future<EmployeeEntity> createEmployee(EmployeeEntity employee) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockEmployees.add(employee);
    return employee;
  }

  @override
  Future<EmployeeEntity> updateEmployee(EmployeeEntity employee) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockEmployees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _mockEmployees[index] = employee;
    }
    return employee;
  }

  @override
  Future<void> updateStatus(String id, EmployeeStatus status) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _mockEmployees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final existing = _mockEmployees[index];
      _mockEmployees[index] = EmployeeEntity(
        id: existing.id,
        employeeCode: existing.employeeCode,
        fullName: existing.fullName,
        email: existing.email,
        phone: existing.phone,
        department: existing.department,
        jobTitle: existing.jobTitle,
        workplaceId: existing.workplaceId,
        workplaceName: existing.workplaceName,
        scheduleId: existing.scheduleId,
        scheduleName: existing.scheduleName,
        managerName: existing.managerName,
        status: status,
        joinedDate: existing.joinedDate,
      );
    }
  }
}
