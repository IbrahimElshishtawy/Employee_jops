import '../../../employees/domain/entities/employee_entity.dart';

enum RequestType {
  leave('LEAVE', 'Leave / Vacation'),
  permission('PERMISSION', 'Personal Permission'),
  late('LATE', 'Late Arrival'),
  absence('ABSENCE', 'Excused Absence'),
  halfDay('HALF_DAY', 'Half-Day Leave');

  final String key;
  final String label;

  const RequestType(this.key, this.label);

  static RequestType fromKey(String? key) {
    if (key == null) return RequestType.leave;
    return RequestType.values.firstWhere(
      (t) => t.key.toUpperCase() == key.toUpperCase(),
      orElse: () => RequestType.leave,
    );
  }
}

enum RequestStatus {
  pending('PENDING', 'Pending Approval'),
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected'),
  cancelled('CANCELLED', 'Cancelled');

  final String key;
  final String label;

  const RequestStatus(this.key, this.label);

  static RequestStatus fromKey(String? key) {
    if (key == null) return RequestStatus.pending;
    return RequestStatus.values.firstWhere(
      (s) => s.key.toUpperCase() == key.toUpperCase(),
      orElse: () => RequestStatus.pending,
    );
  }
}

/// Unified Employee Request Entity
class HrRequestEntity {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final RequestType type;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewComment;

  const HrRequestEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.type,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewComment,
  });
}

class RequestFilter {
  final String? searchQuery;
  final RequestType? type;
  final RequestStatus? status;
  final int page;
  final int pageSize;

  const RequestFilter({
    this.searchQuery,
    this.type,
    this.status,
    this.page = 1,
    this.pageSize = 10,
  });
}

abstract class RequestsRepository {
  Future<PaginatedList<HrRequestEntity>> getRequests(RequestFilter filter);
  Future<HrRequestEntity> getRequestById(String id);
  Future<void> reviewRequest(String id, {required bool approve, String? comment});
}
