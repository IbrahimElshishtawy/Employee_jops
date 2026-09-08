import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/training_models.dart';

class TrainingRemoteDataSource {
  final ApiClient apiClient;

  TrainingRemoteDataSource({required this.apiClient});

  Future<List<TrainingCourse>> getCourses() async {
    final response = await apiClient.get(ApiEndpoints.trainingCourses);
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => TrainingCourse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<TrainingCertificate>> getCertificates() async {
    final response = await apiClient.get(ApiEndpoints.trainingCertificates);
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => TrainingCertificate.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
