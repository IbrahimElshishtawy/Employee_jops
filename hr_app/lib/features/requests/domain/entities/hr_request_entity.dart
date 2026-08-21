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

/// Granular audit event for request state transitions
class RequestHistoryEvent {
  final String id;
  final String action; // e.g. "SUBMITTED", "APPROVED", "REJECTED", "CANCELLED"
  final String actor;
  final DateTime timestamp;
  final String? comment;

  const RequestHistoryEvent({
    required this.id,
    required this.action,
    required this.actor,
    required this.timestamp,
    this.comment,
  });
}

/// Aggregated Requests KPI Metrics
class RequestKpiSummary {
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int cancelledCount;

  const RequestKpiSummary({
    required this.totalCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.cancelledCount,
  });
}

/// Unified Employee Request Entity
class HrRequestEntity {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String? department;
  final RequestType type;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime;
  final String? endTime;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewComment;
  final List<String> attachments;
  final List<RequestHistoryEvent> history;

  const HrRequestEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.department = 'Engineering',
    required this.type,
    required this.reason,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewComment,
    this.attachments = const [],
    this.history = const [],
  });

  HrRequestEntity copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    String? department,
    RequestType? type,
    String? reason,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewComment,
    List<String>? attachments,
    List<RequestHistoryEvent>? history,
  }) {
    return HrRequestEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      department: department ?? this.department,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewComment: reviewComment ?? this.reviewComment,
      attachments: attachments ?? this.attachments,
      history: history ?? this.history,
    );
  }
}

class RequestFilter {
  final String? searchQuery;
  final RequestType? type;
  final RequestStatus? status;
  final String? department;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int pageSize;

  const RequestFilter({
    this.searchQuery,
    this.type,
    this.status,
    this.department,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.pageSize = 10,
  });
}

abstract class RequestsRepository {
  Future<PaginatedList<HrRequestEntity>> getRequests(RequestFilter filter);
  Future<HrRequestEntity> getRequestById(String id);
  Future<RequestKpiSummary> getRequestKpis();
  Future<void> reviewRequest(String id, {required bool approve, String? comment});
}
