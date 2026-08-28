import '../entities/department_request.dart';
import '../repositories/communication_repository.dart';

class GetDepartmentRequests {
  final CommunicationRepository repository;

  GetDepartmentRequests(this.repository);

  Future<List<DepartmentRequest>> call(String departmentId) async {
    return await repository.getDepartmentRequests(departmentId);
  }
}
