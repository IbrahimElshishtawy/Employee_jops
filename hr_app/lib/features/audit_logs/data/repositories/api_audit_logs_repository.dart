import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/audit_log_entity.dart';

/// Live Production Audit Logs Repository
class ApiAuditLogsRepository implements AuditLogsRepository {
  final ApiClient _apiClient;

  ApiAuditLogsRepository(this._apiClient);

  @override
  Future<PaginatedList<AuditLogItemEntity>> getAuditLogs(AuditLogFilter filter) async {
    try {
      final queryParams = <String, String>{
        'page': filter.page.toString(),
        'pageSize': filter.pageSize.toString(),
      };
      if (filter.searchQuery != null) queryParams['q'] = filter.searchQuery!;
      if (filter.category != null) queryParams['category'] = filter.category!.name;
      if (filter.result != null) queryParams['result'] = filter.result!.name;
      if (filter.actorRole != null) queryParams['role'] = filter.actorRole!;

      final response = await _apiClient.get(
        ApiEndpoints.auditLogs,
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) => _mapAuditLog(e as Map<String, dynamic>)).toList();

          return PaginatedList<AuditLogItemEntity>(
            items: items,
            totalCount: json['totalCount'] as int? ?? items.length,
            page: json['page'] as int? ?? filter.page,
            pageSize: json['pageSize'] as int? ?? filter.pageSize,
            totalPages: json['totalPages'] as int? ?? 1,
          );
        },
      );

      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<AuditLogItemEntity> getAuditLogById(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.auditLogs}/$id',
        parser: (data) => _mapAuditLog(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<AuditLogKpiSummary> getAuditLogKpis() async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.auditLogs}/kpis',
        parser: (data) {
          final json = data as Map<String, dynamic>;
          return AuditLogKpiSummary(
            totalLogs: json['totalLogs'] as int? ?? 0,
            securityEvents: json['securityEvents'] as int? ?? 0,
            adminActions: json['adminActions'] as int? ?? 0,
            failedOperations: json['failedOperations'] as int? ?? 0,
          );
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  static AuditLogItemEntity _mapAuditLog(Map<String, dynamic> map) {
    return AuditLogItemEntity(
      id: map['id'] as String,
      actorId: map['actorId'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      actorRole: map['actorRole'] as String? ?? '',
      action: map['action'] as String? ?? '',
      category: _parseCategory(map['category'] as String?),
      targetType: map['targetType'] as String? ?? '',
      targetId: map['targetId'] as String? ?? '',
      targetSummary: map['targetSummary'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      result: _parseResult(map['result'] as String?),
      ipAddress: map['ipAddress'] as String? ?? '',
      userAgent: map['userAgent'] as String?,
      reason: map['reason'] as String?,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  static AuditActionCategory _parseCategory(String? str) {
    for (final c in AuditActionCategory.values) {
      if (c.name.toLowerCase() == (str ?? '').toLowerCase()) return c;
    }
    return AuditActionCategory.security;
  }

  static AuditResultStatus _parseResult(String? str) {
    for (final r in AuditResultStatus.values) {
      if (r.name.toLowerCase() == (str ?? '').toLowerCase()) return r;
    }
    return AuditResultStatus.success;
  }
}
