import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/advance_entity.dart';

/// Mock Salary Advances Repository with safe test records, installments, and linked deductions
class MockAdvancesRepository implements AdvancesRepository {
  final List<AdvanceEntity> _mockAdvances = [
    AdvanceEntity(
      id: 'TEST-ADV-001',
      employeeId: 'TEST-EMP-001',
      employeeName: 'Alex Vance (Test)',
      employeeCode: 'CW-001',
      department: 'Engineering',
      currentSalary: 3500.00,
      amount: 600.00,
      currency: 'USD',
      reason: 'Home appliance replacement urgent expense',
      status: AdvanceStatus.pending,
      requestedAt: DateTime.now().subtract(const Duration(hours: 8)),
      installmentCount: 3,
      remainingBalance: 600.00,
    ),
    AdvanceEntity(
      id: 'TEST-ADV-002',
      employeeId: 'TEST-EMP-002',
      employeeName: 'Jordan Miller (Test)',
      employeeCode: 'CW-002',
      department: 'Human Resources',
      currentSalary: 2800.00,
      amount: 400.00,
      approvedAmount: 400.00,
      currency: 'USD',
      reason: 'Medical examination and medication expenses',
      status: AdvanceStatus.approved,
      requestedAt: DateTime.now().subtract(const Duration(days: 45)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 44)),
      reviewedBy: 'HR Admin (Test)',
      notes: 'Approved with standard 2-month installment plan',
      installmentCount: 2,
      installmentAmount: 200.00,
      paidInstallmentCount: 1,
      remainingBalance: 200.00,
      installments: [
        AdvanceInstallment(
          installmentNumber: 1,
          dueDate: DateTime.now().subtract(const Duration(days: 15)),
          amount: 200.00,
          status: InstallmentStatus.paid,
          paidDate: DateTime.now().subtract(const Duration(days: 15)),
          remainingBalance: 200.00,
        ),
        AdvanceInstallment(
          installmentNumber: 2,
          dueDate: DateTime.now().add(const Duration(days: 15)),
          amount: 200.00,
          status: InstallmentStatus.pending,
          remainingBalance: 0.0,
        ),
      ],
      deductions: [
        AdvanceDeduction(
          id: 'DED-001',
          payrollPeriod: 'July 2026 Payroll',
          deductionDate: DateTime.now().subtract(const Duration(days: 15)),
          amount: 200.00,
          status: 'DEDUCTED',
          remainingBalance: 200.00,
        ),
      ],
    ),
    AdvanceEntity(
      id: 'TEST-ADV-003',
      employeeId: 'TEST-EMP-004',
      employeeName: 'Samira Khan (Test)',
      employeeCode: 'CW-004',
      department: 'Finance',
      currentSalary: 3200.00,
      amount: 900.00,
      approvedAmount: 900.00,
      currency: 'USD',
      reason: 'University tuition installment payment',
      status: AdvanceStatus.paid,
      requestedAt: DateTime.now().subtract(const Duration(days: 90)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 89)),
      reviewedBy: 'HR Admin (Test)',
      installmentCount: 3,
      installmentAmount: 300.00,
      paidInstallmentCount: 3,
      remainingBalance: 0.0,
      installments: [
        AdvanceInstallment(
          installmentNumber: 1,
          dueDate: DateTime.now().subtract(const Duration(days: 60)),
          amount: 300.00,
          status: InstallmentStatus.paid,
          paidDate: DateTime.now().subtract(const Duration(days: 60)),
          remainingBalance: 600.00,
        ),
        AdvanceInstallment(
          installmentNumber: 2,
          dueDate: DateTime.now().subtract(const Duration(days: 30)),
          amount: 300.00,
          status: InstallmentStatus.paid,
          paidDate: DateTime.now().subtract(const Duration(days: 30)),
          remainingBalance: 300.00,
        ),
        AdvanceInstallment(
          installmentNumber: 3,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          amount: 300.00,
          status: InstallmentStatus.paid,
          paidDate: DateTime.now().subtract(const Duration(days: 1)),
          remainingBalance: 0.0,
        ),
      ],
      deductions: [
        AdvanceDeduction(
          id: 'DED-002',
          payrollPeriod: 'May 2026 Payroll',
          deductionDate: DateTime.now().subtract(const Duration(days: 60)),
          amount: 300.00,
          remainingBalance: 600.00,
        ),
        AdvanceDeduction(
          id: 'DED-003',
          payrollPeriod: 'June 2026 Payroll',
          deductionDate: DateTime.now().subtract(const Duration(days: 30)),
          amount: 300.00,
          remainingBalance: 300.00,
        ),
        AdvanceDeduction(
          id: 'DED-004',
          payrollPeriod: 'July 2026 Payroll',
          deductionDate: DateTime.now().subtract(const Duration(days: 1)),
          amount: 300.00,
          remainingBalance: 0.0,
        ),
      ],
    ),
    AdvanceEntity(
      id: 'TEST-ADV-004',
      employeeId: 'TEST-EMP-003',
      employeeName: 'Taylor Morgan (Test)',
      employeeCode: 'CW-003',
      department: 'Operations',
      currentSalary: 2400.00,
      amount: 1200.00,
      currency: 'USD',
      reason: 'Vehicle maintenance and tire overhaul',
      status: AdvanceStatus.rejected,
      requestedAt: DateTime.now().subtract(const Duration(days: 5)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 4)),
      reviewedBy: 'HR Admin (Test)',
      rejectionReason: 'Exceeds maximum allowable 30% monthly salary advance threshold (Requested 50%)',
    ),
  ];

  @override
  Future<PaginatedList<AdvanceEntity>> getAdvances(AdvanceFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var results = List<AdvanceEntity>.from(_mockAdvances);

    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = filter.searchQuery!.trim().toLowerCase();
      results = results.where((a) =>
          a.employeeName.toLowerCase().contains(q) ||
          a.employeeCode.toLowerCase().contains(q) ||
          (a.department?.toLowerCase().contains(q) ?? false) ||
          a.reason.toLowerCase().contains(q)).toList();
    }

    if (filter.status != null) {
      results = results.where((a) => a.status == filter.status).toList();
    }

    if (filter.department != null && filter.department!.isNotEmpty) {
      results = results.where((a) => a.department?.toLowerCase() == filter.department!.toLowerCase()).toList();
    }

    if (filter.startDate != null) {
      results = results.where((a) => a.requestedAt.isAfter(filter.startDate!.subtract(const Duration(seconds: 1)))).toList();
    }

    if (filter.endDate != null) {
      results = results.where((a) => a.requestedAt.isBefore(filter.endDate!.add(const Duration(days: 1)))).toList();
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
  Future<AdvanceEntity> getAdvanceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockAdvances.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception('Advance not found with ID: $id'),
    );
  }

  @override
  Future<AdvanceKpiSummary> getAdvanceKpis() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final pendingList = _mockAdvances.where((a) => a.status == AdvanceStatus.pending);
    final approvedList = _mockAdvances.where((a) => a.status == AdvanceStatus.approved || a.status == AdvanceStatus.paid);

    final totalRequested = _mockAdvances.fold<double>(0.0, (sum, a) => sum + a.amount);
    final totalApproved = approvedList.fold<double>(0.0, (sum, a) => sum + (a.approvedAmount ?? a.amount));
    final outstanding = _mockAdvances.fold<double>(0.0, (sum, a) => sum + a.remainingBalance);
    final monthlyDeduction = approvedList.fold<double>(0.0, (sum, a) => sum + (a.installmentAmount ?? 0.0));

    return AdvanceKpiSummary(
      totalCount: _mockAdvances.length,
      pendingCount: pendingList.length,
      approvedCount: _mockAdvances.where((a) => a.status == AdvanceStatus.approved).length,
      rejectedCount: _mockAdvances.where((a) => a.status == AdvanceStatus.rejected).length,
      totalRequestedAmount: totalRequested,
      totalApprovedAmount: totalApproved,
      outstandingBalance: outstanding,
      monthlyDeductionTotal: monthlyDeduction,
    );
  }

  @override
  Future<void> approveAdvance(
    String id, {
    required double approvedAmount,
    int? installmentCount,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _mockAdvances.indexWhere((a) => a.id == id);
    if (index != -1) {
      final existing = _mockAdvances[index];
      final count = installmentCount ?? existing.installmentCount;
      final perInstallment = approvedAmount / count;

      final generatedInstallments = List.generate(count, (i) {
        return AdvanceInstallment(
          installmentNumber: i + 1,
          dueDate: DateTime.now().add(Duration(days: (i + 1) * 30)),
          amount: perInstallment,
          status: InstallmentStatus.pending,
          remainingBalance: approvedAmount - ((i + 1) * perInstallment),
        );
      });

      _mockAdvances[index] = existing.copyWith(
        status: AdvanceStatus.approved,
        approvedAmount: approvedAmount,
        installmentCount: count,
        installmentAmount: perInstallment,
        remainingBalance: approvedAmount,
        reviewedAt: DateTime.now(),
        reviewedBy: 'HR Admin (Test)',
        notes: notes,
        installments: generatedInstallments,
      );
    }
  }

  @override
  Future<void> rejectAdvance(String id, {required String reason}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _mockAdvances.indexWhere((a) => a.id == id);
    if (index != -1) {
      final existing = _mockAdvances[index];
      _mockAdvances[index] = existing.copyWith(
        status: AdvanceStatus.rejected,
        reviewedAt: DateTime.now(),
        reviewedBy: 'HR Admin (Test)',
        rejectionReason: reason,
      );
    }
  }
}
