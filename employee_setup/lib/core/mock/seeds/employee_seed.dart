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
      );
}
