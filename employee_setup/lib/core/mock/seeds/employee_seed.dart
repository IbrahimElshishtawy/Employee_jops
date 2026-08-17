import 'package:employee_setup/features/auth/domain/models/employee.dart';

/// The single canonical employee used across the entire app.
/// All repositories, screens, and providers must reference this.
class EmployeeSeed {
  static const String id = 'EMP-1024';
  static const String email = 'employee@company.com';

  static Employee get employee => Employee(
    id: id,
    name: 'إبراهيم الششتاوي',
    email: email,
    department: 'الهندسة البرمجية',
    jobTitle: 'Senior Software Developer',
    avatarUrl: '',
    phone: '01000000000',
    joinDate: DateTime(2025, 1, 15),
    isActive: true,
    // Onboarding fields - seed with false to trigger onboarding flow
    nationalId: '30001010100000',
    googleId: 'google_id_12345',
    onboardingCompleted: false,
    biometricEnabled: false,
    region: 'القاهرة',
    managerId: 'MGR-001',
    workLocationId: 'LOC-CAIRO-HQ',
  );
}
