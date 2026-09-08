import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../domain/models/training_models.dart';
import '../datasources/training_remote_data_source.dart';

final trainingRemoteDataSourceProvider =
    Provider<TrainingRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainingRemoteDataSource(apiClient: apiClient);
});

final trainingCoursesProvider =
    FutureProvider.autoDispose<List<TrainingCourse>>((ref) async {
  final ds = ref.watch(trainingRemoteDataSourceProvider);
  try {
    return await ds.getCourses();
  } catch (e) {
    return [];
  }
});

final trainingCertificatesProvider =
    FutureProvider.autoDispose<List<TrainingCertificate>>((ref) async {
  final ds = ref.watch(trainingRemoteDataSourceProvider);
  try {
    return await ds.getCertificates();
  } catch (e) {
    return [];
  }
});

class TrainingRepository {
  final TrainingRemoteDataSource _dataSource;

  TrainingRepository({required TrainingRemoteDataSource dataSource})
      : _dataSource = dataSource;

  Future<List<TrainingCourse>> getCourses() => _dataSource.getCourses();
  Future<List<TrainingCertificate>> getCertificates() =>
      _dataSource.getCertificates();
}

final trainingRepositoryProvider = Provider<TrainingRepository>((ref) {
  final ds = ref.watch(trainingRemoteDataSourceProvider);
  return TrainingRepository(dataSource: ds);
});
