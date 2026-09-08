import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/employee_report.dart';

class ReportsRemoteDataSource {
  final ApiClient apiClient;

  ReportsRemoteDataSource({required this.apiClient});

  Future<EmployeeReport> getMyReport(
      {String? startDate, String? endDate}) async {
    final response = await apiClient.get(
      ApiEndpoints.reportsMe,
      queryParameters: {
        'startDate': ?startDate,
        'endDate': ?endDate,
      },
    );
    return EmployeeReport.fromJson(response.data as Map<String, dynamic>);
  }
}
