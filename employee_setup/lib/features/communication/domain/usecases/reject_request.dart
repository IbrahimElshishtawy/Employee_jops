import '../entities/department_request.dart';
import '../repositories/communication_repository.dart';

class RejectRequest {
  final CommunicationRepository repository;

  RejectRequest(this.repository);

  Future<DepartmentRequest> call(String requestId, {String? reason}) async {
    return await repository.rejectRequest(requestId, reason: reason);
  }
}
