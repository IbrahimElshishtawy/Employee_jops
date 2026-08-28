import '../entities/department_request.dart';
import '../repositories/communication_repository.dart';

class AcceptRequest {
  final CommunicationRepository repository;

  AcceptRequest(this.repository);

  Future<DepartmentRequest> call(String requestId) async {
    return await repository.acceptRequest(requestId);
  }
}
