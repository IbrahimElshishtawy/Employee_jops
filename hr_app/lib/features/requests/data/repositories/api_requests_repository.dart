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

      final response = await _apiClient.get(
        ApiEndpoints.requests,
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) {
            final map = e as Map<String, dynamic>;
            return HrRequestEntity(
              id: map['id'] as String,
              employeeId: map['employeeId'] as String,
              employeeName: map['employeeName'] as String? ?? '',
              employeeCode: map['employeeCode'] as String? ?? '',
              type: RequestType.fromKey(map['type'] as String?),
              reason: map['reason'] as String? ?? '',
              startDate: DateTime.parse(map['startDate'] as String),
              endDate: DateTime.parse(map['endDate'] as String),
              status: RequestStatus.fromKey(map['status'] as String?),
              createdAt: DateTime.parse(map['createdAt'] as String),
              reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt'] as String) : null,
              reviewedBy: map['reviewedBy'] as String?,
              reviewComment: map['reviewComment'] as String?,
            );
          }).toList();

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
        parser: (data) {
          final map = data as Map<String, dynamic>;
          return HrRequestEntity(
            id: map['id'] as String,
            employeeId: map['employeeId'] as String,
            employeeName: map['employeeName'] as String? ?? '',
            employeeCode: map['employeeCode'] as String? ?? '',
            type: RequestType.fromKey(map['type'] as String?),
            reason: map['reason'] as String? ?? '',
            startDate: DateTime.parse(map['startDate'] as String),
            endDate: DateTime.parse(map['endDate'] as String),
            status: RequestStatus.fromKey(map['status'] as String?),
            createdAt: DateTime.parse(map['createdAt'] as String),
            reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt'] as String) : null,
            reviewedBy: map['reviewedBy'] as String?,
            reviewComment: map['reviewComment'] as String?,
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
          'comment': comment,
        },
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }
}
