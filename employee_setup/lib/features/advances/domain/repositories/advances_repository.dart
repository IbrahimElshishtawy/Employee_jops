import '../models/advance_request.dart';
import '../models/expense_report.dart';

abstract class AdvancesRepository {
  Future<List<AdvanceRequest>> getAdvances(String employeeId);
  Future<AdvanceRequest?> getAdvanceById(String id);
  Future<AdvanceRequest> createAdvance({
    required String employeeId,
    required double amount,
    required String reason,
    String? details,
    int installments = 1,
    String? attachmentName,
  });
  Future<ExpenseReport> submitExpenseReport(ExpenseReport report);
  Future<ExpenseReport?> getExpenseReport(String advanceId);
  Future<void> resetToDefaultMock();
}
