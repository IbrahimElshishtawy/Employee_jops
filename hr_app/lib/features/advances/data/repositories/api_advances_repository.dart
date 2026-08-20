import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/advance_entity.dart';

/// Live Production Advances Repository
class ApiAdvancesRepository implements AdvancesRepository {
  final ApiClient _apiClient;

  ApiAdvancesRepository(this._apiClient);

  @override
  Future<PaginatedList<AdvanceEntity>> getAdvances(AdvanceFilter filter) async {
    try {
      final queryParams = <String, String>{
        'page': filter.page.toString(),
        'pageSize': filter.pageSize.toString(),
      };
      if (filter.searchQuery != null) queryParams['q'] = filter.searchQuery!;
      if (filter.status != null) queryParams['status'] = filter.status!.key;

      final response = await _apiClient.get(
        ApiEndpoints.advances,
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) {
            final map = e as Map<String, dynamic>;
            return AdvanceEntity(
              id: map['id'] as String,
              employeeId: map['employeeId'] as String,
              employeeName: map['employeeName'] as String? ?? '',
              employeeCode: map['employeeCode'] as String? ?? '',
              amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
              currency: map['currency'] as String? ?? 'USD',
              reason: map['reason'] as String? ?? '',
              status: AdvanceStatus.fromKey(map['status'] as String?),
              requestedAt: DateTime.parse(map['requestedAt'] as String),
              reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt'] as String) : null,
              reviewedBy: map['reviewedBy'] as String?,
              notes: map['notes'] as String?,
            );
          }).toList();

          return PaginatedList<AdvanceEntity>(
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
  Future<void> reviewAdvance(String id, {required bool approve, String? notes}) async {
    try {
      await _apiClient.post(
        ApiEndpoints.advanceReview(id),
        body: {
          'status': approve ? 'APPROVED' : 'REJECTED',
          'notes': notes,
        },
      );
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }
}
