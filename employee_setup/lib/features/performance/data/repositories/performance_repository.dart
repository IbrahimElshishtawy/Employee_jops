import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../domain/models/performance_models.dart';
import '../datasources/performance_remote_data_source.dart';

final performanceRemoteDataSourceProvider =
    Provider<PerformanceRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PerformanceRemoteDataSource(apiClient: apiClient);
});

final performanceGoalsProvider =
    FutureProvider.autoDispose<List<PerformanceGoal>>((ref) async {
  final ds = ref.watch(performanceRemoteDataSourceProvider);
  try {
    return await ds.getGoals();
  } catch (e) {
    return [];
  }
});

final performanceReviewsProvider =
    FutureProvider.autoDispose<List<PerformanceReview>>((ref) async {
  final ds = ref.watch(performanceRemoteDataSourceProvider);
  try {
    return await ds.getReviews();
  } catch (e) {
    return [];
  }
});

class PerformanceRepository {
  final PerformanceRemoteDataSource _dataSource;

  PerformanceRepository({required PerformanceRemoteDataSource dataSource})
      : _dataSource = dataSource;

  Future<List<PerformanceGoal>> getGoals() => _dataSource.getGoals();

  Future<PerformanceGoal> updateGoalProgress(
          String id, double currentValue, String? notes) =>
      _dataSource.updateGoalProgress(id, currentValue, notes);

  Future<List<PerformanceReview>> getReviews() => _dataSource.getReviews();

  Future<void> acknowledgeReview(String id) =>
      _dataSource.acknowledgeReview(id);
}

final performanceRepositoryProvider = Provider<PerformanceRepository>((ref) {
  final ds = ref.watch(performanceRemoteDataSourceProvider);
  return PerformanceRepository(dataSource: ds);
});
