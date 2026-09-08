import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../data/datasources/tasks_remote_data_source.dart';
import '../../data/repositories/tasks_repository.dart';
import '../../domain/models/task_model.dart';

final tasksRemoteDataSourceProvider = Provider<TasksRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return TasksRemoteDataSource(client);
});

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final ds = ref.watch(tasksRemoteDataSourceProvider);
  return RealTasksRepository(ds);
});

final tasksListProvider = FutureProvider.autoDispose<List<TaskItem>>((ref) async {
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.getMyTasks();
});

final taskDetailsProvider =
    FutureProvider.autoDispose.family<TaskItem?, String>((ref, id) async {
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.getTaskById(id);
});
