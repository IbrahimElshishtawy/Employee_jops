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
  final String? nationalId;
  final double? basicSalary;
  final double? allowances;
  final String? bankAccountNumber;

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
    this.nationalId,
    this.basicSalary,
    this.allowances,
    this.bankAccountNumber,
  });

  EmployeeEntity copyWith({
    String? id,
    String? employeeCode,
    String? fullName,
    String? email,
    String? phone,
    String? department,
    String? jobTitle,
    String? workplaceId,
    String? workplaceName,
    String? scheduleId,
    String? scheduleName,
    String? managerName,
    EmployeeStatus? status,
    DateTime? joinedDate,
    String? nationalId,
    double? basicSalary,
    double? allowances,
    String? bankAccountNumber,
  }) {
    return EmployeeEntity(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      jobTitle: jobTitle ?? this.jobTitle,
      workplaceId: workplaceId ?? this.workplaceId,
      workplaceName: workplaceName ?? this.workplaceName,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduleName: scheduleName ?? this.scheduleName,
      managerName: managerName ?? this.managerName,
      status: status ?? this.status,
      joinedDate: joinedDate ?? this.joinedDate,
      nationalId: nationalId ?? this.nationalId,
      basicSalary: basicSalary ?? this.basicSalary,
      allowances: allowances ?? this.allowances,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
    );
  }
}

class EmployeeFilter {
  final String? searchQuery;
  final String? department;
  final EmployeeStatus? status;
  final String? workplaceId;
  final String? scheduleId;
  final int page;
  final int pageSize;

  const EmployeeFilter({
    this.searchQuery,
    this.department,
    this.status,
    this.workplaceId,
    this.scheduleId,
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
  Future<void> assignWorkplaceAndSchedule(
    String id, {
    required String workplaceId,
    required String workplaceName,
    required String scheduleId,
    required String scheduleName,
  });
}
