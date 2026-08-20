import '../../../employees/domain/entities/employee_entity.dart';

enum DeductionType {
  penalty('PENALTY', 'Disciplinary Penalty'),
  absence('ABSENCE', 'Unexcused Absence'),
  loanRepayment('LOAN_REPAYMENT', 'Loan Repayment'),
  damage('DAMAGE', 'Asset Damage'),
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

/// Deduction Record Entity
class DeductionEntity {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final DeductionType type;
  final double amount;
  final String reason;
  final DateTime date;
  final String createdBy;

  const DeductionEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.type,
    required this.amount,
    required this.reason,
    required this.date,
    required this.createdBy,
  });
}

abstract class DeductionsRepository {
  Future<PaginatedList<DeductionEntity>> getDeductions(int page, int pageSize);
  Future<DeductionEntity> createDeduction(DeductionEntity deduction);
}

class MockDeductionsRepository implements DeductionsRepository {
  final List<DeductionEntity> _mockDeductions = [
    DeductionEntity(
      id: 'TEST-DED-001',
      employeeId: 'TEST-EMP-003',
      employeeName: 'Taylor Morgan (Test)',
      employeeCode: 'CW-003',
      type: DeductionType.absence,
      amount: 75.00,
      reason: 'Unexcused full-day absence without prior notice',
      date: DateTime.now().subtract(const Duration(days: 4)),
      createdBy: 'HR Admin (Test)',
    ),
    DeductionEntity(
      id: 'TEST-DED-002',
      employeeId: 'TEST-EMP-005',
      employeeName: 'Casey Davis (Test)',
      employeeCode: 'CW-005',
      type: DeductionType.penalty,
      amount: 50.00,
      reason: 'Repeated unexcused late arrivals (>30m)',
      date: DateTime.now().subtract(const Duration(days: 8)),
      createdBy: 'HR Admin (Test)',
    ),
  ];

  @override
  Future<PaginatedList<DeductionEntity>> getDeductions(int page, int pageSize) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return PaginatedList<DeductionEntity>(
      items: _mockDeductions,
      totalCount: _mockDeductions.length,
      page: page,
      pageSize: pageSize,
      totalPages: 1,
    );
  }

  @override
  Future<DeductionEntity> createDeduction(DeductionEntity deduction) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockDeductions.add(deduction);
    return deduction;
  }
}
