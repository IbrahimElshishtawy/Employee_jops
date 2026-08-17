class Employee {
  final String id;
  final String name;
  final String email;
  final String department;
  final String jobTitle;
  final String avatarUrl;
  final String phone;
  final DateTime joinDate;
  final bool isActive;
  final String? managerName;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.jobTitle,
    required this.avatarUrl,
    required this.phone,
    required this.joinDate,
    this.isActive = true,
    this.managerName,
  });

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? jobTitle,
    String? avatarUrl,
    String? phone,
    DateTime? joinDate,
    bool? isActive,
    String? managerName,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      jobTitle: jobTitle ?? this.jobTitle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
      managerName: managerName ?? this.managerName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'department': department,
        'jobTitle': jobTitle,
        'avatarUrl': avatarUrl,
        'phone': phone,
        'joinDate': joinDate.toIso8601String(),
        'isActive': isActive,
        'managerName': managerName,
      };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        department: json['department'] as String,
        jobTitle: json['jobTitle'] as String,
        avatarUrl: json['avatarUrl'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        joinDate: json['joinDate'] != null
            ? DateTime.parse(json['joinDate'] as String)
            : DateTime(2023, 1, 1),
        isActive: json['isActive'] as bool? ?? true,
        managerName: json['managerName'] as String?,
      );

  // Default Mock Employee (delegates to EmployeeSeed — kept for backward compat)
  static Employee get defaultMock => Employee(
        id: 'EMP-1024',
        name: 'إبراهيم الششتاوي',
        email: 'employee@company.com',
        department: 'الهندسة البرمجية',
        jobTitle: 'Senior Software Developer',
        avatarUrl: '',
        phone: '01000000000',
        joinDate: DateTime(2025, 1, 15),
        managerName: 'Ahmed Mohamed',
      );
}
