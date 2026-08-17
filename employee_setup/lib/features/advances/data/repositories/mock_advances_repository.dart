import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/advance_request.dart';
import '../../domain/models/expense_report.dart';
import '../../domain/repositories/advances_repository.dart';

class MockAdvancesRepository implements AdvancesRepository {
  final Uuid _uuid = const Uuid();
  final List<AdvanceRequest> _advances = [];
  final Map<String, ExpenseReport> _reports = {};

  MockAdvancesRepository() {
    _initMockData();
  }

  void _initMockData() {
    _advances.clear();
    _reports.clear();

    final now = DateTime.now();
    _advances.addAll([
      AdvanceRequest(
        id: 'adv-001',
        employeeId: AppConstants.mockEmployeeId,
        amount: 3500.0,
        reason: 'مصروفات مؤتمر البرمجيات السنوي ومعدات تطوير',
        details: 'تغطية تذاكر السفر وحجز فندق الإقامة لحضور المؤتمر التقني',
        installments: 3,
        createdAt: now.subtract(const Duration(days: 14)),
        status: AdvanceStatus.reportRequired,
        approvedAt: now.subtract(const Duration(days: 12)),
        attachmentName: 'conference_invoice.pdf',
      ),
      AdvanceRequest(
        id: 'adv-002',
        employeeId: AppConstants.mockEmployeeId,
        amount: 1500.0,
        reason: 'سُلفة شخصية طارئة',
        details: 'ظروف عائلية خاصة مع خصم القسط من الراتب القادم',
        installments: 1,
        createdAt: now.subtract(const Duration(days: 4)),
        status: AdvanceStatus.approved,
        approvedAt: now.subtract(const Duration(days: 2)),
      ),
      AdvanceRequest(
        id: 'adv-003',
        employeeId: AppConstants.mockEmployeeId,
        amount: 5000.0,
        reason: 'تجديد شهادات احترافية سحابية Cloud Certification',
        details: 'رسوم امتحانات AWS Solutions Architect',
        installments: 2,
        createdAt: now.subtract(const Duration(days: 1)),
        status: AdvanceStatus.pending,
      ),
    ]);
  }

  @override
  Future<List<AdvanceRequest>> getAdvances(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_advances);
  }

  @override
  Future<AdvanceRequest?> getAdvanceById(String id) async {
    try {
      return _advances.firstWhere((element) => element.id == id);
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
    await Future.delayed(const Duration(milliseconds: 400));

    final newAdvance = AdvanceRequest(
      id: 'adv-${_uuid.v4().substring(0, 6)}',
      employeeId: employeeId,
      amount: amount,
      reason: reason,
      details: details,
      installments: installments,
      createdAt: DateTime.now(),
      status: AdvanceStatus.pending,
      attachmentName: attachmentName,
    );

    _advances.insert(0, newAdvance);
    return newAdvance;
  }

  @override
  Future<ExpenseReport> submitExpenseReport(ExpenseReport report) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _reports[report.advanceId] = report;

    // Update status of related advance
    final index = _advances.indexWhere((element) => element.id == report.advanceId);
    if (index != -1) {
      _advances[index] = _advances[index].copyWith(status: AdvanceStatus.reportSubmitted);
    }

    return report;
  }

  @override
  Future<ExpenseReport?> getExpenseReport(String advanceId) async {
    return _reports[advanceId];
  }

  @override
  Future<void> resetToDefaultMock() async {
    _initMockData();
  }
}
