import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/announcement_model.dart';

class AnnouncementsRepository {
  final ApiClient apiClient;

  const AnnouncementsRepository(this.apiClient);

  Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.announcements,
        fromData: (data) {
          if (data is List) {
            return data.map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <AnnouncementModel>[];
        },
      );
      return response.data ?? _mockAnnouncements();
    } on ApiException catch (e) {
      SecureLogger.error('AnnouncementsRepository', 'Failed to fetch announcements', e);
      return _mockAnnouncements();
    }
  }

  Future<bool> acknowledgeAnnouncement(String id) async {
    try {
      final response = await apiClient.post(ApiEndpoints.readAnnouncement(id));
      return response.success;
    } catch (e) {
      return false;
    }
  }

  List<AnnouncementModel> _mockAnnouncements() {
    return [
      AnnouncementModel(
        id: 'ann-1',
        title: 'تحديث سياسات السلامة والصحة المهنية لعام 2026',
        content: 'نحيطكم علماً باعتماد لائحة السلامة الجديدة، ويجب على جميع الموظفين قراءتها والالتزام بها.',
        category: 'POLICY',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
        requiresAcknowledgment: true,
      ),
      AnnouncementModel(
        id: 'ann-2',
        title: 'تهنئة بفوز الفندق بجائزة التميز الفندقي',
        content: 'تتقدم الإدارة بالشكر لكافة العاملين على جهودهم المتميزة التي تكللت بحصولنا على الجائزة.',
        category: 'GENERAL',
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }
}
