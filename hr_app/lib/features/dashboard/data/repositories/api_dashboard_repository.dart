import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/dashboard_metrics.dart';

/// Live Production Dashboard Repository
class ApiDashboardRepository implements DashboardRepository {
  final ApiClient _apiClient;

  ApiDashboardRepository(this._apiClient);

  @override
  Future<DashboardMetrics> getMetrics() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.dashboardMetrics,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          return DashboardMetrics(
            totalEmployees: json['totalEmployees'] as int? ?? 0,
            presentToday: json['presentToday'] as int? ?? 0,
            lateToday: json['lateToday'] as int? ?? 0,
            absentToday: json['absentToday'] as int? ?? 0,
            pendingRequests: json['pendingRequests'] as int? ?? 0,
            pendingAdvances: json['pendingAdvances'] as int? ?? 0,
            checkInsToday: json['checkInsToday'] as int? ?? 0,
            checkOutsToday: json['checkOutsToday'] as int? ?? 0,
            attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
          );
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }
}
