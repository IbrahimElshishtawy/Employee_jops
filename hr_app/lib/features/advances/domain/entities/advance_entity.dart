import '../../../employees/domain/entities/employee_entity.dart';

enum AdvanceStatus {
  pending('PENDING', 'Pending Approval'),
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected'),
  paid('PAID', 'Paid / Disbursed'),
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

/// Salary Advance Domain Entity
class AdvanceEntity {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final double amount;
  final String currency;
  final String reason;
  final AdvanceStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? notes;

  const AdvanceEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.amount,
    this.currency = 'USD',
    required this.reason,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.notes,
  });
}

class AdvanceFilter {
  final String? searchQuery;
  final AdvanceStatus? status;
  final int page;
  final int pageSize;

  const AdvanceFilter({
    this.searchQuery,
    this.status,
    this.page = 1,
    this.pageSize = 10,
  });
}

abstract class AdvancesRepository {
  Future<PaginatedList<AdvanceEntity>> getAdvances(AdvanceFilter filter);
  Future<void> reviewAdvance(String id, {required bool approve, String? notes});
}
