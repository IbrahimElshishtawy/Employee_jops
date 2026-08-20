enum EmployeeStatus {
  active('ACTIVE', 'Active'),
  suspended('SUSPENDED', 'Suspended'),
  deactivated('DEACTIVATED', 'Deactivated');

  final String key;
  final String label;

  const EmployeeStatus(this.key, this.label);

  static EmployeeStatus fromKey(String? key) {
    if (key == null) return EmployeeStatus.active;
    return EmployeeStatus.values.firstWhere(
      (s) => s.key.toUpperCase() == key.toUpperCase(),
      orElse: () => EmployeeStatus.active,
    );
  }
}

/// Core Employee Domain Entity
class EmployeeEntity {
  final String id;
  final String employeeCode;
  final String fullName;
  final String email;
  final String phone;
  final String department;
  final String jobTitle;
  final String workplaceId;
  final String workplaceName;
  final String scheduleId;
  final String scheduleName;
  final String? managerName;
  final EmployeeStatus status;
  final DateTime joinedDate;

  const EmployeeEntity({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.department,
    required this.jobTitle,
    required this.workplaceId,
    required this.workplaceName,
    required this.scheduleId,
    required this.scheduleName,
    this.managerName,
    required this.status,
    required this.joinedDate,
  });
}

class EmployeeFilter {
  final String? searchQuery;
  final String? department;
  final EmployeeStatus? status;
  final String? workplaceId;
  final int page;
  final int pageSize;

  const EmployeeFilter({
    this.searchQuery,
    this.department,
    this.status,
    this.workplaceId,
    this.page = 1,
    this.pageSize = 10,
  });
}

class PaginatedList<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedList({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });
}

abstract class EmployeeRepository {
  Future<PaginatedList<EmployeeEntity>> getEmployees(EmployeeFilter filter);
  Future<EmployeeEntity> getEmployeeById(String id);
  Future<EmployeeEntity> createEmployee(EmployeeEntity employee);
  Future<EmployeeEntity> updateEmployee(EmployeeEntity employee);
  Future<void> updateStatus(String id, EmployeeStatus status);
}
