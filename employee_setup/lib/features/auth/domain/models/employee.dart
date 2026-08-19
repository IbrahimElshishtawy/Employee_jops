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

  // Workplace & Attendance configuration fields
  final String? workplaceName;
  final double? workplaceLatitude;
  final double? workplaceLongitude;
  final double allowedRadiusMeters;
  final String? workStartTime;
  final String? workEndTime;
  final String? hrContactName;
  final String? hrContactPhone;
  final String? employeeStatus;

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
    this.workplaceName,
    this.workplaceLatitude,
    this.workplaceLongitude,
    this.allowedRadiusMeters = 4.0,
    this.workStartTime,
    this.workEndTime,
    this.hrContactName,
    this.hrContactPhone,
    this.employeeStatus = 'active',
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
    String? workplaceName,
    double? workplaceLatitude,
    double? workplaceLongitude,
    double? allowedRadiusMeters,
    String? workStartTime,
    String? workEndTime,
    String? hrContactName,
    String? hrContactPhone,
    String? employeeStatus,
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
      workplaceName: workplaceName ?? this.workplaceName,
      workplaceLatitude: workplaceLatitude ?? this.workplaceLatitude,
      workplaceLongitude: workplaceLongitude ?? this.workplaceLongitude,
      allowedRadiusMeters: allowedRadiusMeters ?? this.allowedRadiusMeters,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      hrContactName: hrContactName ?? this.hrContactName,
      hrContactPhone: hrContactPhone ?? this.hrContactPhone,
      employeeStatus: employeeStatus ?? this.employeeStatus,
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
    'workplaceName': workplaceName,
    'workplaceLatitude': workplaceLatitude,
    'workplaceLongitude': workplaceLongitude,
    'allowedRadiusMeters': allowedRadiusMeters,
    'workStartTime': workStartTime,
    'workEndTime': workEndTime,
    'hrContactName': hrContactName,
    'hrContactPhone': hrContactPhone,
    'employeeStatus': employeeStatus,
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
    workplaceName: json['workplaceName'] as String?,
    workplaceLatitude: (json['workplaceLatitude'] as num?)?.toDouble(),
    workplaceLongitude: (json['workplaceLongitude'] as num?)?.toDouble(),
    allowedRadiusMeters: (json['allowedRadiusMeters'] as num?)?.toDouble() ?? 4.0,
    workStartTime: json['workStartTime'] as String?,
    workEndTime: json['workEndTime'] as String?,
    hrContactName: json['hrContactName'] as String?,
    hrContactPhone: json['hrContactPhone'] as String?,
    employeeStatus: json['employeeStatus'] as String? ?? 'active',
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
    workplaceName: 'المقر الرئيسي - القاهرة',
    workplaceLatitude: 30.044400,
    workplaceLongitude: 31.235700,
    allowedRadiusMeters: 4.0,
    workStartTime: '09:00 AM',
    workEndTime: '05:00 PM',
    hrContactName: 'سارة عبد الله',
    hrContactPhone: '01011122233',
    employeeStatus: 'active',
  );
}
