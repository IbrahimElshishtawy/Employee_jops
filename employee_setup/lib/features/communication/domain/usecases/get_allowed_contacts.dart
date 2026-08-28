import '../entities/employee_contact.dart';
import '../repositories/communication_repository.dart';

class GetAllowedContacts {
  final CommunicationRepository repository;

  GetAllowedContacts(this.repository);

  Future<List<EmployeeContact>> call({required String departmentId}) async {
    return await repository.getAllowedContacts(departmentId: departmentId);
  }
}
