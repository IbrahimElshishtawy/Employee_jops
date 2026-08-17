import 'package:employee_setup/features/advances/data/repositories/mock_advances_repository.dart';
import 'package:employee_setup/features/advances/domain/models/advance_request.dart';
import 'package:employee_setup/features/advances/domain/models/expense_report.dart';
import 'package:employee_setup/features/permissions/data/repositories/mock_permissions_repository.dart';
import 'package:employee_setup/features/permissions/domain/models/permission_request.dart';
import 'package:employee_setup/features/requests/domain/repositories/requests_repository.dart';
import 'package:employee_setup/features/vacations/data/repositories/mock_vacations_repository.dart';
import 'package:employee_setup/features/vacations/domain/models/vacation_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Requests Hub & Sub-Features Tests', () {
    late MockAdvancesRepository advancesRepo;
    late MockPermissionsRepository permissionsRepo;
    late MockVacationsRepository vacationsRepo;
    late MockRequestsRepository requestsRepo;

    setUp(() {
      advancesRepo = MockAdvancesRepository();
      permissionsRepo = MockPermissionsRepository();
      vacationsRepo = MockVacationsRepository();
      requestsRepo = MockRequestsRepository(
        advancesRepo: advancesRepo,
        permissionsRepo: permissionsRepo,
        vacationsRepo: vacationsRepo,
      );
    });

    test('Create Advance adds to repository', () async {
      final adv = await advancesRepo.createAdvance(
        employeeId: 'EMP-1024',
        amount: 3000,
        reason: 'مصاريف تدريب',
        installments: 3,
      );

      expect(adv.amount, equals(3000));
      expect(adv.status, equals(AdvanceStatus.pending));

      final list = await advancesRepo.getAdvances('EMP-1024');
      expect(list.first.id, equals(adv.id));
    });

    test('Submit Expense Report updates advance status to reportSubmitted', () async {
      final list = await advancesRepo.getAdvances('EMP-1024');
      final target = list.first;

      final report = ExpenseReport(
        id: 'rep-001',
        advanceId: target.id,
        employeeId: 'EMP-1024',
        totalAmount: target.amount,
        items: [
          ExpenseItem(
            id: 'item-1',
            description: 'تذكرة طيران',
            amount: target.amount,
            date: DateTime.now(),
          ),
        ],
        submittedAt: DateTime.now(),
      );

      await advancesRepo.submitExpenseReport(report);

      final updated = await advancesRepo.getAdvanceById(target.id);
      expect(updated?.status, equals(AdvanceStatus.reportSubmitted));
    });

    test('Create Permission Request', () async {
      final perm = await permissionsRepo.createPermission(
        employeeId: 'EMP-1024',
        type: PermissionType.earlyLeave,
        date: DateTime.now(),
        durationOrTime: 'ساعة واحدة',
        reason: 'ظرف خاص',
      );

      expect(perm.type, equals(PermissionType.earlyLeave));
      expect(perm.status, equals(PermissionStatus.pending));
    });

    test('Create Vacation Request', () async {
      final vac = await vacationsRepo.createVacation(
        employeeId: 'EMP-1024',
        type: VacationType.annual,
        fromDate: DateTime.now().add(const Duration(days: 5)),
        toDate: DateTime.now().add(const Duration(days: 9)),
        daysCount: 5,
        reason: 'إجازة عائلية',
      );

      expect(vac.daysCount, equals(5));
      expect(vac.type, equals(VacationType.annual));
      expect(vac.status, equals(VacationStatus.pending));
    });

    test('Unified Requests Repository aggregates and sorts all items by date', () async {
      final all = await requestsRepo.getAllRequests('EMP-1024');
      expect(all, isNotEmpty);
      for (int i = 0; i < all.length - 1; i++) {
        expect(all[i].date.isAfter(all[i + 1].date) || all[i].date.isAtSameMomentAs(all[i + 1].date), isTrue);
      }
    });
  });
}
