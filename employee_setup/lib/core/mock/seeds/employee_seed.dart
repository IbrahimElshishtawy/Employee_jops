import 'package:employee_setup/features/auth/domain/models/employee.dart';

/// The canonical test employee used across the test environment (DEVICE_TEST_DATA).
class EmployeeSeed {
  static const String id = 'TEST-001';
  static const String email = 'employee.test@example.com';
  static const String name = 'Device Test Employee';
  static const String nationalId = 'TEST-NATIONAL-ID';
  static const String phone = '01000000000';
  static const String workplace = 'CyberWise IE - Test Office';
  static const String manager = 'Test Manager';
  static const String hr = 'Test HR';
  static const String dataSource = 'DEVICE_TEST_DATA';

  static Employee get employee => Employee(
    id: id,
    name: name,
    email: email,
    department: 'الهندسة البرمجية',
    jobTitle: 'Senior Software Developer',
    avatarUrl: '',
    phone: phone,
    joinDate: DateTime(2025, 1, 15),
    isActive: true,
    managerName: manager,
    nationalId: nationalId,
    googleId: 'google_test_id_001',
    googleName: name,
    googleEmail: email,
    // Initial state is false to enforce first-time onboarding check
    onboardingCompleted: false,
    biometricEnabled: false,
    region: 'القاهرة',
    managerId: 'MGR-001',
    workLocationId: 'LOC-TEST-OFFICE',
    workplaceName: workplace,
    workplaceLatitude: 30.044400,
    workplaceLongitude: 31.235700,
    allowedRadiusMeters: 4.0,
    workStartTime: '09:00 AM',
    workEndTime: '05:00 PM',
    hrContactName: hr,
    hrContactPhone: '01011122233',
    employeeStatus: 'active',
    dataSource: dataSource,
  );
}
