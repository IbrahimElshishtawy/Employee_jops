import '../models/vacation_request.dart';

abstract class VacationsRepository {
  Future<List<VacationRequest>> getVacations(String employeeId);
  Future<VacationRequest?> getVacationById(String id);
  Future<VacationRequest> createVacation({
    required String employeeId,
    required VacationType type,
    required DateTime fromDate,
    required DateTime toDate,
    required int daysCount,
    required String reason,
    String? attachmentName,
  });
  Future<void> resetToDefaultMock();
}
