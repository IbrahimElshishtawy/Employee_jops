import '../../../../core/mock/mock_database.dart';
import '../../domain/models/advance_request.dart';
import '../../domain/models/expense_report.dart';
import '../../domain/repositories/advances_repository.dart';
import '../datasources/advances_remote_data_source.dart';

class RealAdvancesRepository implements AdvancesRepository {
  final AdvancesRemoteDataSource remoteDataSource;
  final MockDatabaseNotifier db;

  RealAdvancesRepository({
    required this.remoteDataSource,
    required this.db,
  });

  @override
  Future<List<AdvanceRequest>> getAdvances(String employeeId) async {
    final remoteAdvances = await remoteDataSource.getMyAdvances();
    if (remoteAdvances.isNotEmpty) {
      return remoteAdvances;
    }
    return db.advances.where((a) => a.employeeId == employeeId).toList();
  }

  @override
  Future<AdvanceRequest?> getAdvanceById(String id) async {
    final remoteAdvance = await remoteDataSource.getAdvanceById(id);
    if (remoteAdvance != null) {
      return remoteAdvance;
    }
    return db.advances.where((a) => a.id == id).firstOrNull;
  }

  @override
  Future<AdvanceRequest> createAdvance({
    required String employeeId,
    required double amount,
    required String reason,
    String? details,
    int installments = 1,
    String? attachmentName,
  }) async {
    final newAdvance = AdvanceRequest(
      id: 'ADV-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: employeeId,
      amount: amount,
      reason: reason,
      details: details,
      installments: installments,
      createdAt: DateTime.now(),
      status: AdvanceStatus.pending,
      attachmentName: attachmentName,
    );

    try {
      final created = await remoteDataSource.submitAdvance(newAdvance);
      db.addAdvance(created);
      return created;
    } catch (_) {
      // Local fallback
      db.addAdvance(newAdvance);
      return newAdvance;
    }
  }

  @override
  Future<ExpenseReport> submitExpenseReport(ExpenseReport report) async {
    db.addExpenseReport(report);
    return report;
  }

  @override
  Future<ExpenseReport?> getExpenseReport(String advanceId) async {
    return db.expenseReports.where((r) => r.advanceId == advanceId).firstOrNull;
  }

  @override
  Future<void> resetToDefaultMock() async {
    db.resetDataKeepSession();
  }
}
