import '../../../employees/domain/entities/employee_entity.dart';

enum AdvanceStatus {
  pending('PENDING', 'Pending Approval'),
  approved('APPROVED', 'Approved & Active'),
  rejected('REJECTED', 'Rejected'),
  paid('PAID', 'Fully Disbursed / Repaid'),
  cancelled('CANCELLED', 'Cancelled');

  final String key;
  final String label;

  const AdvanceStatus(this.key, this.label);

  static AdvanceStatus fromKey(String? key) {
    if (key == null) return AdvanceStatus.pending;
    return AdvanceStatus.values.firstWhere(
      (s) => s.key.toUpperCase() == key.toUpperCase(),
      orElse: () => AdvanceStatus.pending,
    );
  }
}

enum InstallmentStatus {
  pending('PENDING', 'Pending Payment'),
  paid('PAID', 'Deducted / Paid'),
  overdue('OVERDUE', 'Overdue');

  final String key;
  final String label;

  const InstallmentStatus(this.key, this.label);

  static InstallmentStatus fromKey(String? key) {
    if (key == null) return InstallmentStatus.pending;
    return InstallmentStatus.values.firstWhere(
      (s) => s.key.toUpperCase() == key.toUpperCase(),
      orElse: () => InstallmentStatus.pending,
    );
  }
}

/// Installment scheduled payment breakdown
class AdvanceInstallment {
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final InstallmentStatus status;
  final DateTime? paidDate;
  final double remainingBalance;

  const AdvanceInstallment({
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidDate,
    required this.remainingBalance,
  });
}

/// Linked Payroll Deduction record
class AdvanceDeduction {
  final String id;
  final String payrollPeriod; // e.g. "August 2026 Payroll"
  final DateTime deductionDate;
  final double amount;
  final String status;
  final double remainingBalance;

  const AdvanceDeduction({
    required this.id,
    required this.payrollPeriod,
    required this.deductionDate,
    required this.amount,
    this.status = 'DEDUCTED',
    required this.remainingBalance,
  });
}

/// Aggregated Financial KPIs for Salary Advances
class AdvanceKpiSummary {
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final double totalRequestedAmount;
  final double totalApprovedAmount;
  final double outstandingBalance;
  final double monthlyDeductionTotal;

  const AdvanceKpiSummary({
    required this.totalCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.totalRequestedAmount,
    required this.totalApprovedAmount,
    required this.outstandingBalance,
    required this.monthlyDeductionTotal,
  });
}

/// Salary Advance Domain Entity
class AdvanceEntity {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String? department;
  final double? currentSalary;
  final double amount;
  final double? approvedAmount;
  final String currency;
  final String reason;
  final AdvanceStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? notes;
  final String? rejectionReason;
  final int installmentCount;
  final double? installmentAmount;
  final int paidInstallmentCount;
  final double remainingBalance;
  final List<AdvanceInstallment> installments;
  final List<AdvanceDeduction> deductions;

  const AdvanceEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.department = 'Engineering',
    this.currentSalary,
    required this.amount,
    this.approvedAmount,
    this.currency = 'USD',
    required this.reason,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.notes,
    this.rejectionReason,
    this.installmentCount = 1,
    this.installmentAmount,
    this.paidInstallmentCount = 0,
    this.remainingBalance = 0.0,
    this.installments = const [],
    this.deductions = const [],
  });

  AdvanceEntity copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    String? department,
    double? currentSalary,
    double? amount,
    double? approvedAmount,
    String? currency,
    String? reason,
    AdvanceStatus? status,
    DateTime? requestedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? notes,
    String? rejectionReason,
    int? installmentCount,
    double? installmentAmount,
    int? paidInstallmentCount,
    double? remainingBalance,
    List<AdvanceInstallment>? installments,
    List<AdvanceDeduction>? deductions,
  }) {
    return AdvanceEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      department: department ?? this.department,
      currentSalary: currentSalary ?? this.currentSalary,
      amount: amount ?? this.amount,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      currency: currency ?? this.currency,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      installmentCount: installmentCount ?? this.installmentCount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      paidInstallmentCount: paidInstallmentCount ?? this.paidInstallmentCount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      installments: installments ?? this.installments,
      deductions: deductions ?? this.deductions,
    );
  }
}

class AdvanceFilter {
  final String? searchQuery;
  final AdvanceStatus? status;
  final String? department;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int pageSize;

  const AdvanceFilter({
    this.searchQuery,
    this.status,
    this.department,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.pageSize = 10,
  });
}

abstract class AdvancesRepository {
  Future<PaginatedList<AdvanceEntity>> getAdvances(AdvanceFilter filter);
  Future<AdvanceEntity> getAdvanceById(String id);
  Future<AdvanceKpiSummary> getAdvanceKpis();
  Future<void> approveAdvance(
    String id, {
    required double approvedAmount,
    int? installmentCount,
    String? notes,
  });
  Future<void> rejectAdvance(
    String id, {
    required String reason,
  });
}
