import '../entities/department.dart';
import '../repositories/communication_repository.dart';

class GetDepartments {
  final CommunicationRepository repository;

  GetDepartments(this.repository);

  Future<List<Department>> call() async {
    return await repository.getDepartments();
  }
}
