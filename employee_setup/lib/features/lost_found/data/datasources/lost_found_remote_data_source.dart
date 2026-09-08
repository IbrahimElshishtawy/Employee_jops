import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/lost_found_item.dart';

class LostFoundRemoteDataSource {
  final ApiClient apiClient;

  LostFoundRemoteDataSource({required this.apiClient});

  Future<List<LostFoundItem>> getItems() async {
    final response = await apiClient.get(ApiEndpoints.lostFound);
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => LostFoundItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<LostFoundItem> getItemById(String id) async {
    final response = await apiClient.get(ApiEndpoints.lostFoundById(id));
    return LostFoundItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LostFoundItem> registerItem(Map<String, dynamic> dto) async {
    final response = await apiClient.post(
      ApiEndpoints.lostFound,
      data: dto,
    );
    return LostFoundItem.fromJson(response.data as Map<String, dynamic>);
  }
}
