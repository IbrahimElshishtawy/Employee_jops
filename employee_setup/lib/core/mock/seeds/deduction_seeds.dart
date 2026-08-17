import '../models/deduction.dart';
import '../seeds/employee_seed.dart';

class DeductionSeeds {
  static const String _empId = EmployeeSeed.id;

  static List<Deduction> get deductions => [
        Deduction(
          id: 'DED-001',
          employeeId: _empId,
          amount: 250,
          reason: 'تأخير في الحضور بتاريخ 15 أغسطس 2026',
          reasonType: DeductionReason.lateArrival,
          date: DateTime(2026, 8, 17),
          status: DeductionStatus.applied,
          note: 'تأخير 21 دقيقة عن موعد الدوام الرسمي',
        ),
      ];
}
