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

  // Onboarding fields
  final String? nationalId;
  final String? googleId;
  final bool onboardingCompleted;
  final bool biometricEnabled;
  final String? region;
  final String? managerId;
  final String? workLocationId;

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
    this.nationalId,
    this.googleId,
    this.onboardingCompleted = false,
    this.biometricEnabled = false,
    this.region,
    this.managerId,
    this.workLocationId,
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
    String? nationalId,
    String? googleId,
    bool? onboardingCompleted,
    bool? biometricEnabled,
    String? region,
    String? managerId,
    String? workLocationId,
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
      nationalId: nationalId ?? this.nationalId,
      googleId: googleId ?? this.googleId,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      region: region ?? this.region,
      managerId: managerId ?? this.managerId,
      workLocationId: workLocationId ?? this.workLocationId,
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
    'nationalId': nationalId,
    'googleId': googleId,
    'onboardingCompleted': onboardingCompleted,
    'biometricEnabled': biometricEnabled,
    'region': region,
    'managerId': managerId,
    'workLocationId': workLocationId,
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
    nationalId: json['nationalId'] as String?,
    googleId: json['googleId'] as String?,
    onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    biometricEnabled: json['biometricEnabled'] as bool? ?? false,
    region: json['region'] as String?,
    managerId: json['managerId'] as String?,
    workLocationId: json['workLocationId'] as String?,
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
    onboardingCompleted: false,
  );
}
