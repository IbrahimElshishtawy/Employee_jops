import '../../../employees/domain/entities/employee_entity.dart';

enum AuditActionCategory {
  authentication('Authentication & Sessions'),
  employees('Employee Management'),
  attendance('Attendance & Telemetry'),
  requests('Requests & Approvals'),
  financial('Salary Advances & Deductions'),
  communications('Messages & Broadcasts'),
  security('Security & Settings');

  final String label;
  const AuditActionCategory(this.label);
}

enum AuditResultStatus {
  success('Success'),
  failure('Failure'),
  warning('Warning');

  final String label;
  const AuditResultStatus(this.label);
}

/// Immutable Audit Log Record representing an administrative or security event
class AuditLogItemEntity {
  final String id;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String action;
  final AuditActionCategory category;
  final String targetType;
  final String targetId;
  final String? targetSummary;
  final DateTime timestamp;
  final AuditResultStatus result;
  final String ipAddress;
  final String? userAgent;
  final String? reason;
  final Map<String, dynamic> metadata;

  const AuditLogItemEntity({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.category,
    required this.targetType,
    required this.targetId,
    this.targetSummary,
    required this.timestamp,
    this.result = AuditResultStatus.success,
    required this.ipAddress,
    this.userAgent,
    this.reason,
    this.metadata = const {},
  });
}

/// Aggregated KPI summary for Audit Logs
class AuditLogKpiSummary {
  final int totalLogs;
  final int securityEvents;
  final int adminActions;
  final int failedOperations;

  const AuditLogKpiSummary({
    required this.totalLogs,
    required this.securityEvents,
    required this.adminActions,
    required this.failedOperations,
  });
}

class AuditLogFilter {
  final String? searchQuery;
  final AuditActionCategory? category;
  final String? actorRole;
  final AuditResultStatus? result;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int pageSize;

  const AuditLogFilter({
    this.searchQuery,
    this.category,
    this.actorRole,
    this.result,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.pageSize = 15,
  });
}

abstract class AuditLogsRepository {
  Future<PaginatedList<AuditLogItemEntity>> getAuditLogs(AuditLogFilter filter);
  Future<AuditLogItemEntity> getAuditLogById(String id);
  Future<AuditLogKpiSummary> getAuditLogKpis();
}
