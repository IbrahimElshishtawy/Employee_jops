import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/performance_models.dart';

class PerformanceRemoteDataSource {
  final ApiClient apiClient;

  PerformanceRemoteDataSource({required this.apiClient});

  Future<List<PerformanceGoal>> getGoals() async {
    final response = await apiClient.get(ApiEndpoints.performanceGoals);
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => PerformanceGoal.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<PerformanceGoal> updateGoalProgress(
      String id, double currentValue, String? notes) async {
    final response = await apiClient.patch(
      ApiEndpoints.updateGoalProgress(id),
      data: {
        'currentValue': currentValue,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return PerformanceGoal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PerformanceReview>> getReviews() async {
    final response = await apiClient.get(ApiEndpoints.performanceReviews);
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => PerformanceReview.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> acknowledgeReview(String id) async {
    await apiClient.post(ApiEndpoints.acknowledgeReview(id));
  }
}
