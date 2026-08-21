import '../../../employees/domain/entities/employee_entity.dart';

enum DeductionStatus {
  scheduled('SCHEDULED', 'Scheduled for Payroll'),
  applied('APPLIED', 'Applied & Deducted'),
  cancelled('CANCELLED', 'Cancelled / Waived'),
  reversed('REVERSED', 'Reversed');

  final String key;
  final String label;

  const DeductionStatus(this.key, this.label);

  static DeductionStatus fromKey(String? key) {
    if (key == null) return DeductionStatus.scheduled;
    return DeductionStatus.values.firstWhere(
      (s) => s.key.toUpperCase() == key.toUpperCase(),
      orElse: () => DeductionStatus.scheduled,
    );
  }
}

enum DeductionType {
  salaryAdvance('SALARY_ADVANCE', 'Salary Advance Installment'),
  penalty('PENALTY', 'Disciplinary Penalty'),
  absence('ABSENCE', 'Unexcused Absence'),
  lateArrival('LATE_ARRIVAL', 'Late Arrival Penalty'),
  damage('DAMAGE', 'Asset Damage / Loss'),
  other('OTHER', 'Other / Miscellaneous');

  final String key;
  final String label;

  const DeductionType(this.key, this.label);

  static DeductionType fromKey(String? key) {
    if (key == null) return DeductionType.penalty;
    return DeductionType.values.firstWhere(
      (d) => d.key.toUpperCase() == key.toUpperCase(),
      orElse: () => DeductionType.penalty,
    );
  }
}

/// Aggregated Financial KPIs for Deductions
class DeductionKpiSummary {
  final int totalCount;
  final double totalAmount;
  final int scheduledCount;
  final double scheduledAmount;
  final int appliedCount;
  final double appliedAmount;
  final double advanceDeductionTotal;
  final double attendanceDeductionTotal;

  const DeductionKpiSummary({
    required this.totalCount,
    required this.totalAmount,
    required this.scheduledCount,
    required this.scheduledAmount,
    required this.appliedCount,
    required this.appliedAmount,
    required this.advanceDeductionTotal,
    required this.attendanceDeductionTotal,
  });
}

/// Deduction Record Entity
class DeductionEntity {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String? department;
  final DeductionType type;
  final double amount;
  final String currency;
  final DeductionStatus status;
  final String payrollPeriod; // e.g. "August 2026 Payroll"
  final String reason;
  final DateTime date;
  final DateTime? appliedDate;
  final String createdBy;
  final String? approvedBy;
  final String? relatedAdvanceId;
  final int? installmentNumber;
  final int? totalInstallments;
  final double? remainingBalance;
  final String? cancellationReason;

  const DeductionEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.department = 'Engineering',
    required this.type,
    required this.amount,
    this.currency = 'USD',
    this.status = DeductionStatus.scheduled,
    this.payrollPeriod = 'August 2026 Payroll',
    required this.reason,
    required this.date,
    this.appliedDate,
    required this.createdBy,
    this.approvedBy,
    this.relatedAdvanceId,
    this.installmentNumber,
    this.totalInstallments,
    this.remainingBalance,
    this.cancellationReason,
  });

  DeductionEntity copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    String? department,
    DeductionType? type,
    double? amount,
    String? currency,
    DeductionStatus? status,
    String? payrollPeriod,
    String? reason,
    DateTime? date,
    DateTime? appliedDate,
    String? createdBy,
    String? approvedBy,
    String? relatedAdvanceId,
    int? installmentNumber,
    int? totalInstallments,
    double? remainingBalance,
    String? cancellationReason,
  }) {
    return DeductionEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      department: department ?? this.department,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      payrollPeriod: payrollPeriod ?? this.payrollPeriod,
      reason: reason ?? this.reason,
      date: date ?? this.date,
      appliedDate: appliedDate ?? this.appliedDate,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      relatedAdvanceId: relatedAdvanceId ?? this.relatedAdvanceId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

class DeductionFilter {
  final String? searchQuery;
  final DeductionType? type;
  final DeductionStatus? status;
  final String? department;
  final String? payrollPeriod;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int pageSize;

  const DeductionFilter({
    this.searchQuery,
    this.type,
    this.status,
    this.department,
    this.payrollPeriod,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.pageSize = 10,
  });
}

abstract class DeductionsRepository {
  Future<PaginatedList<DeductionEntity>> getDeductions(DeductionFilter filter);
  Future<DeductionEntity> getDeductionById(String id);
  Future<DeductionKpiSummary> getDeductionKpis();
  Future<DeductionEntity> createDeduction(DeductionEntity deduction);
  Future<void> cancelDeduction(String id, {required String reason});
}
