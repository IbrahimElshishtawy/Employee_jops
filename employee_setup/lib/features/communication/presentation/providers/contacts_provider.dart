import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/employee_contact.dart';
import 'communication_providers.dart';

final departmentContactsProvider = FutureProvider.family<List<EmployeeContact>, String>((ref, departmentId) async {
  final getAllowedContacts = ref.watch(getAllowedContactsUseCaseProvider);
  return await getAllowedContacts(departmentId: departmentId);
});

final contactByIdProvider = FutureProvider.family<EmployeeContact?, String>((ref, contactId) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return await repo.getContactById(contactId);
});
