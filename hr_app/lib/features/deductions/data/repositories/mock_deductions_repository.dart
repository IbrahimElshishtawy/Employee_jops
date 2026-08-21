import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/deduction_entity.dart';

/// Mock Deductions Repository with rich test records, salary advance linkages, and cancellations
class MockDeductionsRepository implements DeductionsRepository {
  final List<DeductionEntity> _mockDeductions = [
    DeductionEntity(
      id: 'TEST-DED-001',
      employeeId: 'TEST-EMP-001',
      employeeName: 'Alex Vance (Test)',
      employeeCode: 'CW-001',
      department: 'Engineering',
      type: DeductionType.salaryAdvance,
      amount: 200.00,
      currency: 'USD',
      status: DeductionStatus.scheduled,
      payrollPeriod: 'August 2026 Payroll',
      reason: 'Monthly repayment installment for emergency repair advance',
      date: DateTime.now().subtract(const Duration(days: 2)),
      createdBy: 'System (Advance Approval)',
      relatedAdvanceId: 'TEST-ADV-001',
      installmentNumber: 1,
      totalInstallments: 3,
      remainingBalance: 400.00,
    ),
    DeductionEntity(
      id: 'TEST-DED-002',
      employeeId: 'TEST-EMP-002',
      employeeName: 'Jordan Miller (Test)',
      employeeCode: 'CW-002',
      department: 'Human Resources',
      type: DeductionType.salaryAdvance,
      amount: 200.00,
      currency: 'USD',
      status: DeductionStatus.applied,
      payrollPeriod: 'July 2026 Payroll',
      reason: 'Installment 1 of 2 for medical checkup advance',
      date: DateTime.now().subtract(const Duration(days: 20)),
      appliedDate: DateTime.now().subtract(const Duration(days: 15)),
      createdBy: 'System (Advance Approval)',
      approvedBy: 'HR Admin (Test)',
      relatedAdvanceId: 'TEST-ADV-002',
      installmentNumber: 1,
      totalInstallments: 2,
      remainingBalance: 200.00,
    ),
    DeductionEntity(
      id: 'TEST-DED-003',
      employeeId: 'TEST-EMP-003',
      employeeName: 'Taylor Morgan (Test)',
      employeeCode: 'CW-003',
      department: 'Operations',
      type: DeductionType.absence,
      amount: 75.00,
      currency: 'USD',
      status: DeductionStatus.applied,
      payrollPeriod: 'July 2026 Payroll',
      reason: 'Unexcused full-day absence without prior notice or medical certificate',
      date: DateTime.now().subtract(const Duration(days: 18)),
      appliedDate: DateTime.now().subtract(const Duration(days: 15)),
      createdBy: 'HR Admin (Test)',
      approvedBy: 'HR Manager (Test)',
    ),
    DeductionEntity(
      id: 'TEST-DED-004',
      employeeId: 'TEST-EMP-004',
      employeeName: 'Samira Khan (Test)',
      employeeCode: 'CW-004',
      department: 'Finance',
      type: DeductionType.lateArrival,
      amount: 35.00,
      currency: 'USD',
      status: DeductionStatus.scheduled,
      payrollPeriod: 'August 2026 Payroll',
      reason: 'Cumulative unexcused late arrivals (>45 mins total in period)',
      date: DateTime.now().subtract(const Duration(days: 3)),
      createdBy: 'System (Attendance Payroll Rules)',
    ),
    DeductionEntity(
      id: 'TEST-DED-005',
      employeeId: 'TEST-EMP-005',
      employeeName: 'Casey Davis (Test)',
      employeeCode: 'CW-005',
      department: 'Marketing',
      type: DeductionType.penalty,
      amount: 50.00,
      currency: 'USD',
      status: DeductionStatus.cancelled,
      payrollPeriod: 'July 2026 Payroll',
      reason: 'Disciplinary penalty for missed mandatory client sprint delivery',
      date: DateTime.now().subtract(const Duration(days: 25)),
      createdBy: 'HR Admin (Test)',
      cancellationReason: 'Waived upon formal written justification submitted by department lead',
    ),
  ];

  @override
  Future<PaginatedList<DeductionEntity>> getDeductions(DeductionFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var results = List<DeductionEntity>.from(_mockDeductions);

    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = filter.searchQuery!.trim().toLowerCase();
      results = results.where((d) =>
          d.employeeName.toLowerCase().contains(q) ||
          d.employeeCode.toLowerCase().contains(q) ||
          (d.department?.toLowerCase().contains(q) ?? false) ||
          d.reason.toLowerCase().contains(q) ||
          d.payrollPeriod.toLowerCase().contains(q)).toList();
    }

    if (filter.type != null) {
      results = results.where((d) => d.type == filter.type).toList();
    }

    if (filter.status != null) {
      results = results.where((d) => d.status == filter.status).toList();
    }

    if (filter.department != null && filter.department!.isNotEmpty) {
      results = results.where((d) => d.department?.toLowerCase() == filter.department!.toLowerCase()).toList();
    }

    if (filter.payrollPeriod != null && filter.payrollPeriod!.isNotEmpty) {
      results = results.where((d) => d.payrollPeriod.toLowerCase() == filter.payrollPeriod!.toLowerCase()).toList();
    }

    if (filter.startDate != null) {
      results = results.where((d) => d.date.isAfter(filter.startDate!.subtract(const Duration(seconds: 1)))).toList();
    }

    if (filter.endDate != null) {
      results = results.where((d) => d.date.isBefore(filter.endDate!.add(const Duration(days: 1)))).toList();
    }

    final totalCount = results.length;
    final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 999);
    final startIndex = ((filter.page - 1) * filter.pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + filter.pageSize).clamp(0, totalCount);

    return PaginatedList<DeductionEntity>(
      items: results.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<DeductionEntity> getDeductionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockDeductions.firstWhere(
      (d) => d.id == id,
      orElse: () => throw Exception('Deduction not found with ID: $id'),
    );
  }

  @override
  Future<DeductionKpiSummary> getDeductionKpis() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final scheduledList = _mockDeductions.where((d) => d.status == DeductionStatus.scheduled);
    final appliedList = _mockDeductions.where((d) => d.status == DeductionStatus.applied);
    final advanceList = _mockDeductions.where((d) => d.type == DeductionType.salaryAdvance);
    final attendanceList = _mockDeductions.where((d) => d.type == DeductionType.absence || d.type == DeductionType.lateArrival);

    final totalAmount = _mockDeductions.where((d) => d.status != DeductionStatus.cancelled).fold<double>(0.0, (s, d) => s + d.amount);
    final scheduledAmount = scheduledList.fold<double>(0.0, (s, d) => s + d.amount);
    final appliedAmount = appliedList.fold<double>(0.0, (s, d) => s + d.amount);
    final advanceTotal = advanceList.fold<double>(0.0, (s, d) => s + d.amount);
    final attendanceTotal = attendanceList.fold<double>(0.0, (s, d) => s + d.amount);

    return DeductionKpiSummary(
      totalCount: _mockDeductions.length,
      totalAmount: totalAmount,
      scheduledCount: scheduledList.length,
      scheduledAmount: scheduledAmount,
      appliedCount: appliedList.length,
      appliedAmount: appliedAmount,
      advanceDeductionTotal: advanceTotal,
      attendanceDeductionTotal: attendanceTotal,
    );
  }

  @override
  Future<DeductionEntity> createDeduction(DeductionEntity deduction) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _mockDeductions.insert(0, deduction);
    return deduction;
  }

  @override
  Future<void> cancelDeduction(String id, {required String reason}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _mockDeductions.indexWhere((d) => d.id == id);
    if (index != -1) {
      final existing = _mockDeductions[index];
      _mockDeductions[index] = existing.copyWith(
        status: DeductionStatus.cancelled,
        cancellationReason: reason,
      );
    }
  }
}
