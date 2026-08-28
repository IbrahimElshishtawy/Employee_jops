import '../entities/department_request.dart';
import '../repositories/communication_repository.dart';

class GetMyRequests {
  final CommunicationRepository repository;

  GetMyRequests(this.repository);

  Future<List<DepartmentRequest>> call() async {
    return await repository.getMyRequests();
  }
}
