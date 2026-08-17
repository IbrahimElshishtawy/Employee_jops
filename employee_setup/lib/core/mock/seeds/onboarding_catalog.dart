/// Static catalog of dropdown options for onboarding screens.
/// NOT displayed in UI — consumed via Riverpod provider.
class OnboardingCatalog {
  // Job titles
  static const List<String> jobTitles = [
    'Software Engineer',
    'Senior Software Engineer',
    'HR Specialist',
    'Financial Analyst',
    'Sales Manager',
    'Product Manager',
    'DevOps Engineer',
    'QA Engineer',
    'Business Analyst',
    'Data Scientist',
  ];

  // Departments (Arabic)
  static const List<String> departments = [
    'الهندسة البرمجية',
    'الموارد البشرية',
    'المالية',
    'المبيعات',
    'التسويق',
    'العمليات',
    'الدعم الفني',
    'البحث والتطوير',
  ];

  // Regions (Arabic)
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

  // Managers (mock data)
  static final List<ManagerInfo> managers = [
    ManagerInfo(
      id: 'MGR-001',
      name: 'Ahmed Mohamed',
      department: 'الهندسة البرمجية',
    ),
    ManagerInfo(
      id: 'MGR-002',
      name: 'Fatima Mansour',
      department: 'الموارد البشرية',
    ),
    ManagerInfo(id: 'MGR-003', name: 'Karim Hassan', department: 'المالية'),
    ManagerInfo(id: 'MGR-004', name: 'Noor Ibrahim', department: 'المبيعات'),
    ManagerInfo(id: 'MGR-005', name: 'Sarah Abdullah', department: 'التسويق'),
  ];

  // HR Contact info
  static const HrContact hrContact = HrContact(
    name: 'Human Resources Team',
    email: 'hr@company.com',
    phone: '+20 100 123 4567',
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
