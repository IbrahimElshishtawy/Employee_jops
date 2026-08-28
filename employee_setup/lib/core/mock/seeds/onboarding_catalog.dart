/// Employee System Role
enum EmployeeRole {
  employee,
  supervisor,
  manager,
  admin;

  String get roleName => name.toUpperCase();
}

/// Employee Hierarchy Level
enum HierarchyLevel {
  staff,
  supervisor,
  executive;

  String get levelName => name.toUpperCase();
}

/// Static catalog of options for onboarding screens.
class OnboardingCatalog {
  // Predefined Job Titles (Arabic & English representations)
  static const List<String> jobTitles = [
    'Receptionist',
    'Front Office Manager',
    'Security Guard',
    'Security Supervisor',
    'Room Attendant',
    'Housekeeping Supervisor',
    'Waiter',
    'Captain',
    'Chef',
    'Accountant',
    'HR Specialist',
    'Engineer',
    'IT Support',
    'Software Engineer',
    'Senior Software Engineer',
    'Financial Analyst',
    'Sales Manager',
    'Product Manager',
    'DevOps Engineer',
    'QA Engineer',
    'Business Analyst',
    'Data Scientist',
  ];

  // Predefined Departments
  static const List<String> departments = [
    'Front Office',
    'Housekeeping',
    'Food & Beverage',
    'Kitchen',
    'Engineering',
    'Security',
    'Human Resources',
    'Finance / Accounting',
    'Sales & Marketing',
    'Reservations',
    'Purchasing',
    'IT',
    'Banquets & Events',
    'Recreation',
    'الهندسة البرمجية',
    'الموارد البشرية',
    'المالية',
    'المبيعات',
    'التسويق',
    'العمليات',
    'الدعم الفني',
    'البحث والتطوير',
  ];

  // Legacy regions for compatibility
  static const List<String> regions = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'أسيوط',
    'قنا',
    'أسوان',
    'طنطا',
    'المنصورة',
  ];

  // Legacy Managers (mock test data for backward compatibility)
  static final List<ManagerInfo> managers = [
    ManagerInfo(
      id: 'MGR-001',
      name: 'Test Manager (Ahmed Mohamed)',
      department: 'Front Office',
    ),
    ManagerInfo(
      id: 'MGR-002',
      name: 'Fatima Mansour',
      department: 'Human Resources',
    ),
    ManagerInfo(id: 'MGR-003', name: 'Karim Hassan', department: 'Finance / Accounting'),
    ManagerInfo(id: 'MGR-004', name: 'Noor Ibrahim', department: 'Sales & Marketing'),
    ManagerInfo(id: 'MGR-005', name: 'Sarah Abdullah', department: 'IT'),
  ];

  // Legacy HR Contact info
  static const HrContact hrContact = HrContact(
    name: 'Test HR (CyberWise IE Support)',
    email: 'hr.test@example.com',
    phone: '01011122233',
  );
}

/// Manager info for dropdowns
class ManagerInfo {
  final String id;
  final String name;
  final String department;

  const ManagerInfo({
    required this.id,
    required this.name,
    required this.department,
  });

  @override
  String toString() => name;
}

/// HR Contact info
class HrContact {
  final String name;
  final String email;
  final String phone;

  const HrContact({
    required this.name,
    required this.email,
    required this.phone,
  });
}
