import '../entities/department_request.dart';
import '../repositories/communication_repository.dart';

class StartRequest {
  final CommunicationRepository repository;

  StartRequest(this.repository);

  Future<DepartmentRequest> call(String requestId) async {
    return await repository.startRequest(requestId);
  }
}
