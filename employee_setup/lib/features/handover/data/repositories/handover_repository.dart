import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/handover_model.dart';

class HandoverRepository {
  final ApiClient apiClient;

  const HandoverRepository(this.apiClient);

  Future<List<HandoverReport>> getHandovers() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.handover,
        fromData: (data) {
          if (data is List) {
            return data.map((e) => HandoverReport.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <HandoverReport>[];
        },
      );
      return response.data ?? _mockHandovers();
    } on ApiException catch (e) {
      SecureLogger.error('HandoverRepository', 'Get handovers error', e);
      return _mockHandovers();
    }
  }

  Future<bool> acknowledgeHandover(String id) async {
    try {
      final response = await apiClient.patch(ApiEndpoints.acknowledgeHandover(id));
      return response.success;
    } catch (_) {
      return false;
    }
  }

  List<HandoverReport> _mockHandovers() {
    return [
      HandoverReport(
        id: 'hnd-001',
        outgoingEmployeeName: 'أحمد محمود (الوردية الصباحية)',
        incomingEmployeeName: 'محمود سامي (الوردية المسائية)',
        department: 'الاستقبال وخدمة النزلاء',
        shiftName: 'الوردية الصباحية (08:00 - 16:00)',
        handoverTime: DateTime.now().subtract(const Duration(hours: 1)),
        notes: 'تم تسليم صندوق العهدة ومفاتيح الغرف الشاغرة.',
        isAcknowledged: false,
        pendingItems: const [
          HandoverItem(
            id: 'item-1',
            description: 'غرفة 402 تحتاج فحص تسريب مياه قبل تسكين النزيل القادم.',
            status: 'PENDING',
            priority: 'URGENT',
          ),
        ],
      ),
    ];
  }
}
