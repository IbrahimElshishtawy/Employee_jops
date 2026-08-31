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

/// Model for centralized Job Title catalog entry with stable ID and localized names
class JobTitleOption {
  final String id;
  final String nameAr;
  final String nameEn;

  const JobTitleOption({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobTitleOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model for centralized Department catalog entry with stable ID, localized names and emoji
class DepartmentOption {
  final String id;
  final String nameAr;
  final String nameEn;
  final String emoji;

  const DepartmentOption({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.emoji,
  });

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Static catalog of options for onboarding screens.
class OnboardingCatalog {
  // Predefined Job Titles (Structured with stable IDs and Arabic & English names)
  static const List<JobTitleOption> jobTitleOptions = [
    JobTitleOption(id: 'RECEPTIONIST', nameAr: 'موظف استقبال', nameEn: 'Receptionist'),
    JobTitleOption(id: 'FRONT_OFFICE_MANAGER', nameAr: 'مدير مكتب الاستقبال', nameEn: 'Front Office Manager'),
    JobTitleOption(id: 'GUEST_RELATIONS', nameAr: 'علاقات النزلاء', nameEn: 'Guest Relations'),
    JobTitleOption(id: 'CONCIERGE', nameAr: 'كونسيرج', nameEn: 'Concierge'),
    JobTitleOption(id: 'BELLMAN', nameAr: 'موظف خدمات النزلاء', nameEn: 'Bellman'),
    JobTitleOption(id: 'SECURITY_GUARD', nameAr: 'فرد أمن', nameEn: 'Security Guard'),
    JobTitleOption(id: 'SECURITY_SUPERVISOR', nameAr: 'مشرف أمن', nameEn: 'Security Supervisor'),
    JobTitleOption(id: 'HOUSEKEEPING_SUPERVISOR', nameAr: 'مشرف الإشراف الداخلي', nameEn: 'Housekeeping Supervisor'),
    JobTitleOption(id: 'ROOM_ATTENDANT', nameAr: 'عامل غرف', nameEn: 'Room Attendant'),
    JobTitleOption(id: 'WAITER', nameAr: 'نادل', nameEn: 'Waiter'),
    JobTitleOption(id: 'CAPTAIN', nameAr: 'كابتن صالة', nameEn: 'Captain'),
    JobTitleOption(id: 'RESTAURANT_MANAGER', nameAr: 'مدير مطعم', nameEn: 'Restaurant Manager'),
    JobTitleOption(id: 'CHEF', nameAr: 'شيف', nameEn: 'Chef'),
    JobTitleOption(id: 'SOUS_CHEF', nameAr: 'مساعد الشيف', nameEn: 'Sous Chef'),
    JobTitleOption(id: 'ACCOUNTANT', nameAr: 'محاسب', nameEn: 'Accountant'),
    JobTitleOption(id: 'HR_SPECIALIST', nameAr: 'أخصائي موارد بشرية', nameEn: 'HR Specialist'),
    JobTitleOption(id: 'ENGINEER', nameAr: 'مهندس', nameEn: 'Engineer'),
    JobTitleOption(id: 'TECHNICIAN', nameAr: 'فني', nameEn: 'Technician'),
    JobTitleOption(id: 'IT_SUPPORT', nameAr: 'دعم فني', nameEn: 'IT Support'),
    JobTitleOption(id: 'SALES_EXECUTIVE', nameAr: 'مسؤول مبيعات', nameEn: 'Sales Executive'),
    JobTitleOption(id: 'RESERVATION_AGENT', nameAr: 'موظف حجوزات', nameEn: 'Reservation Agent'),
    JobTitleOption(id: 'STOREKEEPER', nameAr: 'أمين مخزن', nameEn: 'Storekeeper'),
    JobTitleOption(id: 'DRIVER', nameAr: 'سائق', nameEn: 'Driver'),
  ];

  // Predefined Departments (Structured with stable IDs, Arabic & English names, and hotel emojis)
  static const List<DepartmentOption> departmentOptions = [
    DepartmentOption(id: 'FRONT_OFFICE', nameAr: 'مكتب الاستقبال', nameEn: 'Front Office', emoji: '🏨'),
    DepartmentOption(id: 'HOUSEKEEPING', nameAr: 'الإشراف الداخلي', nameEn: 'Housekeeping', emoji: '🧹'),
    DepartmentOption(id: 'FOOD_AND_BEVERAGE', nameAr: 'الأغذية والمشروبات', nameEn: 'Food & Beverage', emoji: '🍽'),
    DepartmentOption(id: 'KITCHEN', nameAr: 'المطبخ', nameEn: 'Kitchen', emoji: '👨‍🍳'),
    DepartmentOption(id: 'ENGINEERING', nameAr: 'الصيانة والهندسة', nameEn: 'Engineering', emoji: '🔧'),
    DepartmentOption(id: 'SECURITY', nameAr: 'الأمن', nameEn: 'Security', emoji: '🛡'),
    DepartmentOption(id: 'HUMAN_RESOURCES', nameAr: 'الموارد البشرية', nameEn: 'Human Resources', emoji: '💼'),
    DepartmentOption(id: 'FINANCE_AND_ACCOUNTING', nameAr: 'الحسابات والمالية', nameEn: 'Finance & Accounting', emoji: '💰'),
    DepartmentOption(id: 'SALES_AND_MARKETING', nameAr: 'المبيعات والتسويق', nameEn: 'Sales & Marketing', emoji: '📈'),
    DepartmentOption(id: 'RESERVATIONS', nameAr: 'الحجوزات', nameEn: 'Reservations', emoji: '📅'),
    DepartmentOption(id: 'PURCHASING', nameAr: 'المشتريات', nameEn: 'Purchasing', emoji: '📦'),
    DepartmentOption(id: 'STORES', nameAr: 'المخازن', nameEn: 'Stores', emoji: '🏬'),
    DepartmentOption(id: 'IT', nameAr: 'تكنولوجيا المعلومات', nameEn: 'IT', emoji: '💻'),
    DepartmentOption(id: 'BANQUETS_AND_EVENTS', nameAr: 'الحفلات والمؤتمرات', nameEn: 'Banquets & Events', emoji: '🎉'),
    DepartmentOption(id: 'RECREATION', nameAr: 'الترفيه', nameEn: 'Recreation', emoji: '🏊'),
  ];

  // Helper getters for backward compatibility with List<String>
  static List<String> get jobTitles => jobTitleOptions.map((e) => e.nameEn).toList();
  static List<String> get departments => departmentOptions.map((e) => e.nameEn).toList();

  static JobTitleOption? findJobTitle(String? queryOrId) {
    if (queryOrId == null || queryOrId.isEmpty) return null;
    final q = queryOrId.toLowerCase().trim();
    return jobTitleOptions
        .where(
          (j) =>
              j.id.toLowerCase() == q ||
              j.nameEn.toLowerCase() == q ||
              j.nameAr.toLowerCase() == q ||
              j.nameEn.toLowerCase().contains(q) ||
              j.nameAr.toLowerCase().contains(q),
        )
        .firstOrNull;
  }

  static DepartmentOption? findDepartment(String? queryOrId) {
    if (queryOrId == null || queryOrId.isEmpty) return null;
    final q = queryOrId.toLowerCase().trim();
    return departmentOptions
        .where(
          (d) =>
              d.id.toLowerCase() == q ||
              d.nameEn.toLowerCase() == q ||
              d.nameAr.toLowerCase() == q ||
              d.nameEn.toLowerCase().contains(q) ||
              d.nameAr.toLowerCase().contains(q),
        )
        .firstOrNull;
  }

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
  final String nameAr;
  final String name;
  final String department;

  const ManagerInfo({
    required this.id,
    required this.name,
    this.nameAr = '',
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
