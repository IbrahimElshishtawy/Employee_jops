import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/department.dart';
import 'communication_providers.dart';

final departmentsListProvider = FutureProvider<List<Department>>((ref) async {
  final getDepartments = ref.watch(getDepartmentsUseCaseProvider);
  return await getDepartments();
});

final departmentByIdProvider = FutureProvider.family<Department?, String>((ref, id) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return await repo.getDepartmentById(id);
});
