import '../../../advances/domain/repositories/advances_repository.dart';
import '../../../permissions/domain/repositories/permissions_repository.dart';
import '../../../vacations/domain/repositories/vacations_repository.dart';
import '../models/unified_request.dart';

abstract class RequestsRepository {
  Future<List<UnifiedRequestItem>> getAllRequests(String employeeId, [bool isArabic = true]);
}

class MockRequestsRepository implements RequestsRepository {
  final AdvancesRepository advancesRepo;
  final PermissionsRepository permissionsRepo;
  final VacationsRepository vacationsRepo;

  MockRequestsRepository({
    required this.advancesRepo,
    required this.permissionsRepo,
    required this.vacationsRepo,
  });

  @override
  Future<List<UnifiedRequestItem>> getAllRequests(String employeeId, [bool isArabic = true]) async {
    final advances = await advancesRepo.getAdvances(employeeId);
    final permissions = await permissionsRepo.getPermissions(employeeId);
    final vacations = await vacationsRepo.getVacations(employeeId);

    final List<UnifiedRequestItem> list = [
      ...advances.map((e) => UnifiedRequestItem.fromAdvance(e, isArabic)),
      ...permissions.map((e) => UnifiedRequestItem.fromPermission(e, isArabic)),
      ...vacations.map((e) => UnifiedRequestItem.fromVacation(e, isArabic)),
    ];

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
