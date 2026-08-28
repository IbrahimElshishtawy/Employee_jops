import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../data/datasources/communication_mock_data_source.dart';
import '../../data/datasources/communication_remote_data_source.dart';
import '../../data/repositories/communication_repository_impl.dart';
import '../../domain/repositories/communication_repository.dart';
import '../../domain/usecases/get_departments.dart';
import '../../domain/usecases/get_allowed_contacts.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/get_or_create_conversation.dart';
import '../../domain/usecases/create_department_request.dart';
import '../../domain/usecases/get_my_requests.dart';
import '../../domain/usecases/get_department_requests.dart';
import '../../domain/usecases/accept_request.dart';
import '../../domain/usecases/reject_request.dart';
import '../../domain/usecases/start_request.dart';
import '../../domain/usecases/complete_request.dart';

// Single source data source instance to maintain state across screens during demo/runtime
final communicationMockDataSourceProvider = Provider<CommunicationRemoteDataSource>((ref) {
  final employee = ref.watch(employeeProvider);
  return CommunicationMockDataSource(
    currentUserId: employee.id.isNotEmpty ? employee.id : 'EMP-001',
    currentUserName: employee.fullName.isNotEmpty ? employee.fullName : 'Ibrahim Elshishtawy',
  );
});

final communicationRepositoryProvider = Provider<CommunicationRepository>((ref) {
  final ds = ref.watch(communicationMockDataSourceProvider);
  final employee = ref.watch(employeeProvider);
  return CommunicationRepositoryImpl(
    remoteDataSource: ds,
    currentUserId: employee.id.isNotEmpty ? employee.id : 'EMP-001',
    currentUserName: employee.fullName.isNotEmpty ? employee.fullName : 'Ibrahim Elshishtawy',
  );
});

// Use case providers
final getDepartmentsUseCaseProvider = Provider<GetDepartments>((ref) {
  return GetDepartments(ref.watch(communicationRepositoryProvider));
});

final getAllowedContactsUseCaseProvider = Provider<GetAllowedContacts>((ref) {
  return GetAllowedContacts(ref.watch(communicationRepositoryProvider));
});

final getConversationsUseCaseProvider = Provider<GetConversations>((ref) {
  return GetConversations(ref.watch(communicationRepositoryProvider));
});

final getMessagesUseCaseProvider = Provider<GetMessages>((ref) {
  return GetMessages(ref.watch(communicationRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessage>((ref) {
  return SendMessage(ref.watch(communicationRepositoryProvider));
});

final getOrCreateConversationUseCaseProvider = Provider<GetOrCreateConversation>((ref) {
  return GetOrCreateConversation(ref.watch(communicationRepositoryProvider));
});

final createDepartmentRequestUseCaseProvider = Provider<CreateDepartmentRequest>((ref) {
  return CreateDepartmentRequest(ref.watch(communicationRepositoryProvider));
});

final getMyRequestsUseCaseProvider = Provider<GetMyRequests>((ref) {
  return GetMyRequests(ref.watch(communicationRepositoryProvider));
});

final getDepartmentRequestsUseCaseProvider = Provider<GetDepartmentRequests>((ref) {
  return GetDepartmentRequests(ref.watch(communicationRepositoryProvider));
});

final acceptRequestUseCaseProvider = Provider<AcceptRequest>((ref) {
  return AcceptRequest(ref.watch(communicationRepositoryProvider));
});

final rejectRequestUseCaseProvider = Provider<RejectRequest>((ref) {
  return RejectRequest(ref.watch(communicationRepositoryProvider));
});

final startRequestUseCaseProvider = Provider<StartRequest>((ref) {
  return StartRequest(ref.watch(communicationRepositoryProvider));
});

final completeRequestUseCaseProvider = Provider<CompleteRequest>((ref) {
  return CompleteRequest(ref.watch(communicationRepositoryProvider));
});
