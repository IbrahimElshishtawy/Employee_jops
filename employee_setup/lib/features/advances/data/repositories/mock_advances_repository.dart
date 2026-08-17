import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/mock/mock_database.dart';
import '../../domain/models/advance_request.dart';
import '../../domain/models/expense_report.dart';
import '../../domain/repositories/advances_repository.dart';

class MockAdvancesRepository implements AdvancesRepository {
  final Ref? _ref;
  final _uuid = const Uuid();

  MockAdvancesRepository([Ref? ref]) : _ref = ref;

  MockDatabaseNotifier get _db =>
      _ref?.read(mockDatabaseProvider.notifier) ?? fallbackMockDatabaseNotifier;
  MockDatabase get _state =>
      _ref?.read(mockDatabaseProvider) ?? fallbackMockDatabaseNotifier.state;

  @override
  Future<List<AdvanceRequest>> getAdvances(String employeeId) async {
    return _state.advances.where((a) => a.employeeId == employeeId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<AdvanceRequest?> getAdvanceById(String id) async {
    try {
      return _state.advances.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
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
    final advance = AdvanceRequest(
      id: 'ADV-${_uuid.v4().substring(0, 6).toUpperCase()}',
      employeeId: employeeId,
      amount: amount,
      reason: reason,
      details: details,
      installments: installments,
      createdAt: DateTime.now(),
      status: AdvanceStatus.pending,
      attachmentName: attachmentName,
    );
    _db.addAdvance(advance);
    return advance;
  }

  @override
  Future<ExpenseReport> submitExpenseReport(ExpenseReport report) async {
    _db.addExpenseReport(report);
    // Mark the related advance as reportSubmitted
    _db.updateAdvanceStatus(report.advanceId, AdvanceStatus.reportSubmitted);
    return report;
  }

  @override
  Future<ExpenseReport?> getExpenseReport(String advanceId) async {
    try {
      return _state.expenseReports.firstWhere((r) => r.advanceId == advanceId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> resetToDefaultMock() async {
    // No-op: MockDatabase.resetDataKeepSession() handles bulk reset
  }
}
