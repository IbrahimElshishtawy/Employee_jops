import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/employee_report.dart';

class ReportsRemoteDataSource {
  final ApiClient _apiClient;

  ReportsRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<EmployeeReport> getMyReport(
      {String? startDate, String? endDate}) async {
    final response = await _apiClient.get(
      ApiEndpoints.reportsMe,
      queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    return EmployeeReport.fromJson(response.data as Map<String, dynamic>);
  }
}
