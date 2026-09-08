import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/incident_model.dart';

class IncidentsRepository {
  final ApiClient apiClient;

  const IncidentsRepository(this.apiClient);

  Future<List<IncidentReport>> getIncidents() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.incidents,
        fromData: (data) {
          if (data is List) {
            return data.map((e) => IncidentReport.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <IncidentReport>[];
        },
      );
      return response.data ?? _mockIncidents();
    } on ApiException catch (e) {
      SecureLogger.error('IncidentsRepository', 'Get incidents error', e);
      return _mockIncidents();
    }
  }

  Future<IncidentReport?> createIncident({
    required String title,
    required String description,
    required String severity,
    required String location,
    String? photoUrl,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.incidents,
        data: {
          'title': title,
          'description': description,
          'severity': severity,
          'location': location,
          'photoUrl': ?photoUrl,
        },
        fromData: (data) => IncidentReport.fromJson(data as Map<String, dynamic>),
      );
      return response.data;
    } catch (e) {
      SecureLogger.error('IncidentsRepository', 'Create incident error', e);
      return null;
    }
  }

  List<IncidentReport> _mockIncidents() {
    return [
      IncidentReport(
        id: 'inc-101',
        title: 'انزلاق مياه بالقرب من مصعد بهو الفندق',
        description: 'تسريب خفيف من مبرد المياه تسبب في بلل الأرضية، تم وضع علامة تحذيرية.',
        severity: 'MEDIUM',
        location: 'بهو الفندق - الدور الأرضي',
        status: 'RESOLVED',
        reportedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
