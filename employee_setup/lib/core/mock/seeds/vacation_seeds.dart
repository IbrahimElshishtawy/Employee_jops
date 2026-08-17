import '../../../features/vacations/domain/models/vacation_request.dart';
import '../seeds/employee_seed.dart';

class VacationSeeds {
  static const String _empId = EmployeeSeed.id;

  static List<VacationRequest> get vacations => [
        VacationRequest(
          id: 'VAC-001',
          employeeId: _empId,
          type: VacationType.annual,
          fromDate: DateTime(2026, 8, 20),
          toDate: DateTime(2026, 8, 21),
          daysCount: 2,
          reason: 'إجازة سنوية مستحقة',
          status: VacationStatus.approved,
          createdAt: DateTime(2026, 8, 15),
          approvedAt: DateTime(2026, 8, 16),
        ),
        VacationRequest(
          id: 'VAC-002',
          employeeId: _empId,
          type: VacationType.sick,
          fromDate: DateTime(2026, 7, 20),
          toDate: DateTime(2026, 7, 21),
          daysCount: 2,
          reason: 'مرض وعلاج',
          status: VacationStatus.approved,
          createdAt: DateTime(2026, 7, 19),
          approvedAt: DateTime(2026, 7, 19, 20, 0),
        ),
        VacationRequest(
          id: 'VAC-003',
          employeeId: _empId,
          type: VacationType.casual,
          fromDate: DateTime(2026, 9, 1),
          toDate: DateTime(2026, 9, 1),
          daysCount: 1,
          reason: 'ظرف عائلي',
          status: VacationStatus.pending,
          createdAt: DateTime(2026, 8, 17),
        ),
      ];
}
