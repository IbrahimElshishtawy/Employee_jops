import '../../domain/entities/employee_entity.dart';

class EmployeeDto {
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
  final String status;
  final String joinedDate;

  const EmployeeDto({
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

  factory EmployeeDto.fromJson(Map<String, dynamic> json) {
    return EmployeeDto(
      id: json['id'] as String,
      employeeCode: json['employeeCode'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      department: json['department'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      workplaceId: json['workplaceId'] as String? ?? '',
      workplaceName: json['workplaceName'] as String? ?? '',
      scheduleId: json['scheduleId'] as String? ?? '',
      scheduleName: json['scheduleName'] as String? ?? '',
      managerName: json['managerName'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      joinedDate: json['joinedDate'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  EmployeeEntity toDomain() {
    return EmployeeEntity(
      id: id,
      employeeCode: employeeCode,
      fullName: fullName,
      email: email,
      phone: phone,
      department: department,
      jobTitle: jobTitle,
      workplaceId: workplaceId,
      workplaceName: workplaceName,
      scheduleId: scheduleId,
      scheduleName: scheduleName,
      managerName: managerName,
      status: EmployeeStatus.fromKey(status),
      joinedDate: DateTime.tryParse(joinedDate) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeCode': employeeCode,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'department': department,
        'jobTitle': jobTitle,
        'workplaceId': workplaceId,
        'workplaceName': workplaceName,
        'scheduleId': scheduleId,
        'scheduleName': scheduleName,
        'managerName': managerName,
        'status': status,
        'joinedDate': joinedDate,
      };
}
