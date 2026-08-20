import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/advance_entity.dart';

/// Mock Salary Advances Repository with safe test records
class MockAdvancesRepository implements AdvancesRepository {
  final List<AdvanceEntity> _mockAdvances = [
    AdvanceEntity(
      id: 'TEST-ADV-001',
      employeeId: 'TEST-EMP-001',
      employeeName: 'Alex Vance (Test)',
      employeeCode: 'CW-001',
      amount: 450.00,
      currency: 'USD',
      reason: 'Home appliance repair urgent expense',
      status: AdvanceStatus.pending,
      requestedAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    AdvanceEntity(
      id: 'TEST-ADV-002',
      employeeId: 'TEST-EMP-002',
      employeeName: 'Jordan Miller (Test)',
      employeeCode: 'CW-002',
      amount: 300.00,
      currency: 'USD',
      reason: 'Medical examination fees',
      status: AdvanceStatus.approved,
      requestedAt: DateTime.now().subtract(const Duration(days: 2)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
      reviewedBy: 'HR Admin (Test)',
    ),
    AdvanceEntity(
      id: 'TEST-ADV-003',
      employeeId: 'TEST-EMP-004',
      employeeName: 'Samira Khan (Test)',
      employeeCode: 'CW-004',
      amount: 600.00,
      currency: 'USD',
      reason: 'Tuition installment',
      status: AdvanceStatus.paid,
      requestedAt: DateTime.now().subtract(const Duration(days: 10)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 9)),
      reviewedBy: 'HR Admin (Test)',
    ),
  ];

  @override
  Future<PaginatedList<AdvanceEntity>> getAdvances(AdvanceFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var results = List<AdvanceEntity>.from(_mockAdvances);

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      results = results.where((a) =>
          a.employeeName.toLowerCase().contains(q) ||
          a.employeeCode.toLowerCase().contains(q) ||
          a.reason.toLowerCase().contains(q)).toList();
    }

    if (filter.status != null) {
      results = results.where((a) => a.status == filter.status).toList();
    }

    final totalCount = results.length;
    final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 999);
    final startIndex = ((filter.page - 1) * filter.pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + filter.pageSize).clamp(0, totalCount);

    return PaginatedList<AdvanceEntity>(
      items: results.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<void> reviewAdvance(String id, {required bool approve, String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockAdvances.indexWhere((a) => a.id == id);
    if (index != -1) {
      final existing = _mockAdvances[index];
      _mockAdvances[index] = AdvanceEntity(
        id: existing.id,
        employeeId: existing.employeeId,
        employeeName: existing.employeeName,
        employeeCode: existing.employeeCode,
        amount: existing.amount,
        currency: existing.currency,
        reason: existing.reason,
        status: approve ? AdvanceStatus.approved : AdvanceStatus.rejected,
        requestedAt: existing.requestedAt,
        reviewedAt: DateTime.now(),
        reviewedBy: 'HR Admin (Test)',
        notes: notes,
      );
    }
  }
}
