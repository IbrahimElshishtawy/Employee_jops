import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/leave_balances.dart';

class RequestsRemoteDataSource {
  final ApiClient apiClient;

  const RequestsRemoteDataSource(this.apiClient);

  /// GET /api/v1/requests/leave-balances/me
  Future<LeaveBalances> getLeaveBalances() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.leaveBalances,
        fromData: (data) {
          if (data is Map<String, dynamic>) {
            return LeaveBalances.fromJson(data);
          }
          return const LeaveBalances();
        },
      );
      return response.data ?? const LeaveBalances();
    } on ApiException catch (e) {
      SecureLogger.error('RequestsRemoteDataSource', 'Leave balances error', e);
      return const LeaveBalances();
    }
  }

  /// GET /api/v1/requests/me
  Future<List<Map<String, dynamic>>> getMyRequests() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.myRequests,
        fromData: (data) {
          if (data is List) {
            return data.whereType<Map<String, dynamic>>().toList();
          }
          return <Map<String, dynamic>>[];
        },
      );
      return response.data ?? [];
    } on ApiException catch (e) {
      SecureLogger.error('RequestsRemoteDataSource', 'My requests error', e);
      return [];
    }
  }

  /// POST /api/v1/requests
  Future<Map<String, dynamic>?> createUnifiedRequest(Map<String, dynamic> payload) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.requests,
        data: payload,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on ApiException catch (e) {
      SecureLogger.error('RequestsRemoteDataSource', 'Create request error', e);
      rethrow;
    }
  }

  /// POST /api/v1/requests/:id/cancel
  Future<bool> cancelRequest(String id) async {
    try {
      final response = await apiClient.post(ApiEndpoints.cancelRequest(id));
      return response.success;
    } on ApiException catch (e) {
      SecureLogger.error('RequestsRemoteDataSource', 'Cancel request error', e);
      return false;
    }
  }
}
