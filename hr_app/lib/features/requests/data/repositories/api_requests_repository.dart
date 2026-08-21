import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/hr_request_entity.dart';

/// Live Production Requests Repository
class ApiRequestsRepository implements RequestsRepository {
  final ApiClient _apiClient;

  ApiRequestsRepository(this._apiClient);

  @override
  Future<PaginatedList<HrRequestEntity>> getRequests(RequestFilter filter) async {
    try {
      final queryParams = <String, String>{
        'page': filter.page.toString(),
        'pageSize': filter.pageSize.toString(),
      };
      if (filter.searchQuery != null) queryParams['q'] = filter.searchQuery!;
      if (filter.type != null) queryParams['type'] = filter.type!.key;
      if (filter.status != null) queryParams['status'] = filter.status!.key;
      if (filter.department != null) queryParams['department'] = filter.department!;
      if (filter.startDate != null) queryParams['startDate'] = filter.startDate!.toIso8601String();
      if (filter.endDate != null) queryParams['endDate'] = filter.endDate!.toIso8601String();

      final response = await _apiClient.get(
        ApiEndpoints.requests,
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) => _mapRequest(e as Map<String, dynamic>)).toList();

          return PaginatedList<HrRequestEntity>(
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
  Future<HrRequestEntity> getRequestById(String id) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.requestDetails(id),
        parser: (data) => _mapRequest(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<RequestKpiSummary> getRequestKpis() async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.requests}/kpis',
        parser: (data) {
          final json = data as Map<String, dynamic>;
          return RequestKpiSummary(
            totalCount: json['totalCount'] as int? ?? 0,
            pendingCount: json['pendingCount'] as int? ?? 0,
            approvedCount: json['approvedCount'] as int? ?? 0,
            rejectedCount: json['rejectedCount'] as int? ?? 0,
            cancelledCount: json['cancelledCount'] as int? ?? 0,
          );
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> reviewRequest(String id, {required bool approve, String? comment}) async {
    try {
      await _apiClient.post(
        ApiEndpoints.requestReview(id),
        body: {
          'status': approve ? 'APPROVED' : 'REJECTED',
          'comment': ?comment,
        },
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  static HrRequestEntity _mapRequest(Map<String, dynamic> map) {
    final rawHistory = (map['history'] as List<dynamic>?) ?? [];
    final history = rawHistory.map((h) {
      final hm = h as Map<String, dynamic>;
      return RequestHistoryEvent(
        id: hm['id'] as String,
        action: hm['action'] as String? ?? 'UPDATED',
        actor: hm['actor'] as String? ?? 'System',
        timestamp: DateTime.parse(hm['timestamp'] as String),
        comment: hm['comment'] as String?,
      );
    }).toList();

    return HrRequestEntity(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String? ?? '',
      employeeCode: map['employeeCode'] as String? ?? '',
      department: map['department'] as String?,
      type: RequestType.fromKey(map['type'] as String?),
      reason: map['reason'] as String? ?? '',
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      startTime: map['startTime'] as String?,
      endTime: map['endTime'] as String?,
      status: RequestStatus.fromKey(map['status'] as String?),
      createdAt: DateTime.parse(map['createdAt'] as String),
      reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt'] as String) : null,
      reviewedBy: map['reviewedBy'] as String?,
      reviewComment: map['reviewComment'] as String?,
      attachments: (map['attachments'] as List<dynamic>?)?.map((a) => a.toString()).toList() ?? [],
      history: history,
    );
  }
}
