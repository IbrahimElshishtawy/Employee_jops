import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../domain/models/lost_found_item.dart';
import '../datasources/lost_found_remote_data_source.dart';

final lostFoundRemoteDataSourceProvider =
    Provider<LostFoundRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LostFoundRemoteDataSource(apiClient: apiClient);
});

final lostFoundItemsProvider =
    FutureProvider.autoDispose<List<LostFoundItem>>((ref) async {
  final ds = ref.watch(lostFoundRemoteDataSourceProvider);
  try {
    return await ds.getItems();
  } catch (e) {
    // Return empty list on connection error or fallback
    return [];
  }
});

class LostFoundRepository {
  final LostFoundRemoteDataSource dataSource;

  LostFoundRepository({required this.dataSource});

  Future<List<LostFoundItem>> getItems() => dataSource.getItems();

  Future<LostFoundItem> registerItem(LostFoundItem item) {
    return dataSource.registerItem(item.toCreateDto());
  }
}

final lostFoundRepositoryProvider = Provider<LostFoundRepository>((ref) {
  final ds = ref.watch(lostFoundRemoteDataSourceProvider);
  return LostFoundRepository(dataSource: ds);
});
