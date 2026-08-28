import '../../domain/entities/department.dart';
import '../../domain/entities/employee_contact.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/department_request.dart';
import '../../domain/entities/request_type.dart';
import '../../domain/repositories/communication_repository.dart';
import '../datasources/communication_remote_data_source.dart';
import '../models/department_request_model.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  final CommunicationRemoteDataSource remoteDataSource;
  final String currentUserId;
  final String currentUserName;

  CommunicationRepositoryImpl({
    required this.remoteDataSource,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Future<List<Department>> getDepartments() async {
    return await remoteDataSource.getDepartments();
  }

  @override
  Future<Department?> getDepartmentById(String departmentId) async {
    return await remoteDataSource.getDepartmentById(departmentId);
  }

  @override
  Future<List<EmployeeContact>> getAllowedContacts({required String departmentId}) async {
    return await remoteDataSource.getAllowedContacts(departmentId: departmentId);
  }

  @override
  Future<EmployeeContact?> getContactById(String contactId) async {
    return await remoteDataSource.getContactById(contactId);
  }

  @override
  Future<List<Conversation>> getConversations() async {
    return await remoteDataSource.getConversations();
  }

  @override
  Future<Conversation?> getConversationById(String conversationId) async {
    final convs = await remoteDataSource.getConversations();
    try {
      return convs.firstWhere((c) => c.id == conversationId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Conversation> getOrCreateConversation({
    required String recipientId,
    required String departmentId,
  }) async {
    return await remoteDataSource.getOrCreateConversation(
      recipientId: recipientId,
      departmentId: departmentId,
    );
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    return await remoteDataSource.getMessages(conversationId);
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  }) async {
    return await remoteDataSource.sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      content: content,
    );
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    await remoteDataSource.markConversationAsRead(conversationId);
  }

  @override
  Future<List<RequestType>> getRequestTypes({String? departmentId}) async {
    return await remoteDataSource.getRequestTypes(departmentId: departmentId);
  }

  @override
  Future<List<DepartmentRequest>> getMyRequests() async {
    return await remoteDataSource.getMyRequests();
  }

  @override
  Future<List<DepartmentRequest>> getDepartmentRequests(String departmentId) async {
    return await remoteDataSource.getDepartmentRequests(departmentId);
  }

  @override
  Future<DepartmentRequest?> getRequestById(String requestId) async {
    return await remoteDataSource.getRequestById(requestId);
  }

  @override
  Future<DepartmentRequest> createDepartmentRequest({
    required String departmentId,
    required String requestTypeId,
    required RequestPriority priority,
    required String message,
    String? locationContext,
    String? recipientId,
  }) async {
    final reqModel = DepartmentRequestModel(
      id: '',
      departmentId: departmentId,
      requesterId: currentUserId,
      requesterName: currentUserName,
      recipientId: recipientId,
      requestTypeId: requestTypeId,
      priority: priority,
      message: message,
      locationContext: locationContext,
      createdAt: DateTime.now(),
    );

    return await remoteDataSource.createDepartmentRequest(reqModel);
  }

  @override
  Future<DepartmentRequest> acceptRequest(String requestId) async {
    return await remoteDataSource.updateRequestStatus(
      requestId: requestId,
      status: 'accepted',
    );
  }

  @override
  Future<DepartmentRequest> rejectRequest(String requestId, {String? reason}) async {
    return await remoteDataSource.updateRequestStatus(
      requestId: requestId,
      status: 'rejected',
      reason: reason,
    );
  }

  @override
  Future<DepartmentRequest> startRequest(String requestId) async {
    return await remoteDataSource.updateRequestStatus(
      requestId: requestId,
      status: 'in_progress',
    );
  }

  @override
  Future<DepartmentRequest> completeRequest(String requestId) async {
    return await remoteDataSource.updateRequestStatus(
      requestId: requestId,
      status: 'completed',
    );
  }
}
