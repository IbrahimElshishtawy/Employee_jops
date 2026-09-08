import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/advance_request.dart';

class AdvancesRemoteDataSource {
  final ApiClient apiClient;

  const AdvancesRemoteDataSource(this.apiClient);

  Future<AdvanceRequest> submitAdvance(AdvanceRequest request) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.advances,
        data: request.toBackendDto(),
        fromData: (data) => AdvanceRequest.fromJson(data as Map<String, dynamic>),
      );
      return response.data ?? request;
    } on ApiException catch (e) {
      SecureLogger.error('AdvancesRemoteDataSource', 'Submit advance error', e);
      rethrow;
    }
  }

  Future<List<AdvanceRequest>> getMyAdvances() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.myAdvances,
        fromData: (data) {
          if (data is List) {
            return data
                .whereType<Map<String, dynamic>>()
                .map((e) => AdvanceRequest.fromJson(e))
                .toList();
          }
          return <AdvanceRequest>[];
        },
      );
      return response.data ?? [];
    } on ApiException catch (e) {
      SecureLogger.error('AdvancesRemoteDataSource', 'Get advances error', e);
      return [];
    }
  }

  Future<AdvanceRequest?> getAdvanceById(String id) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.advanceById(id),
        fromData: (data) => AdvanceRequest.fromJson(data as Map<String, dynamic>),
      );
      return response.data;
    } catch (e) {
      SecureLogger.error('AdvancesRemoteDataSource', 'Get advance by id error', e);
      return null;
    }
  }
}
