import '../entities/department_request.dart';
import '../repositories/communication_repository.dart';

class CreateDepartmentRequest {
  final CommunicationRepository repository;

  CreateDepartmentRequest(this.repository);

  Future<DepartmentRequest> call({
    required String departmentId,
    required String requestTypeId,
    required RequestPriority priority,
    required String message,
    String? locationContext,
    String? recipientId,
  }) async {
    return await repository.createDepartmentRequest(
      departmentId: departmentId,
      requestTypeId: requestTypeId,
      priority: priority,
      message: message,
      locationContext: locationContext,
      recipientId: recipientId,
    );
  }
}
