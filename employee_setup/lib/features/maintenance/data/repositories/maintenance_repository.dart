import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/maintenance_model.dart';

class MaintenanceRepository {
  final ApiClient apiClient;

  const MaintenanceRepository(this.apiClient);

  Future<List<MaintenanceOrder>> getMaintenanceRequests() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.maintenanceRequests,
        fromData: (data) {
          if (data is List) {
            return data.map((e) => MaintenanceOrder.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <MaintenanceOrder>[];
        },
      );
      return response.data ?? _mockOrders();
    } on ApiException catch (e) {
      SecureLogger.error('MaintenanceRepository', 'Get maintenance error', e);
      return _mockOrders();
    }
  }

  Future<MaintenanceOrder?> createMaintenanceRequest({
    required String title,
    required String description,
    required String roomOrFacility,
    required String category,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.maintenanceRequests,
        data: {
          'title': title,
          'description': description,
          'room': roomOrFacility,
          'category': category,
        },
        fromData: (data) => MaintenanceOrder.fromJson(data as Map<String, dynamic>),
      );
      return response.data;
    } catch (e) {
      SecureLogger.error('MaintenanceRepository', 'Create order error', e);
      return null;
    }
  }

  List<MaintenanceOrder> _mockOrders() {
    return [
      MaintenanceOrder(
        id: 'MNT-201',
        title: 'إصلاح إضاءة الممر المؤدي للمطعم الرئيسي',
        description: 'بعض المصابيح معطلة وتومض بشكل متقطع.',
        roomOrFacility: 'الممر الشرقي - الدور الأول',
        category: 'ELECTRICAL',
        status: 'IN_PROGRESS',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
