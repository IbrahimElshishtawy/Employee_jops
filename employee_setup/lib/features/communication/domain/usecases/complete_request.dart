import '../entities/department_request.dart';
import '../repositories/communication_repository.dart';

class CompleteRequest {
  final CommunicationRepository repository;

  CompleteRequest(this.repository);

  Future<DepartmentRequest> call(String requestId) async {
    return await repository.completeRequest(requestId);
  }
}
