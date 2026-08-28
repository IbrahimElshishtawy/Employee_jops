import '../entities/department.dart';
import '../entities/employee_contact.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';
import '../entities/department_request.dart';
import '../entities/request_type.dart';

abstract class CommunicationRepository {
  Future<List<Department>> getDepartments();
  Future<Department?> getDepartmentById(String departmentId);
  Future<List<EmployeeContact>> getAllowedContacts({required String departmentId});
  Future<EmployeeContact?> getContactById(String contactId);
  
  // Conversations & Chat
  Future<List<Conversation>> getConversations();
  Future<Conversation?> getConversationById(String conversationId);
  Future<Conversation> getOrCreateConversation({
    required String recipientId,
    required String departmentId,
  });
  Future<List<Message>> getMessages(String conversationId);
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  });
  Future<void> markConversationAsRead(String conversationId);

  // Department Requests
  Future<List<RequestType>> getRequestTypes({String? departmentId});
  Future<List<DepartmentRequest>> getMyRequests();
  Future<List<DepartmentRequest>> getDepartmentRequests(String departmentId);
  Future<DepartmentRequest?> getRequestById(String requestId);
  Future<DepartmentRequest> createDepartmentRequest({
    required String departmentId,
    required String requestTypeId,
    required RequestPriority priority,
    required String message,
    String? locationContext,
    String? recipientId,
  });
  Future<DepartmentRequest> acceptRequest(String requestId);
  Future<DepartmentRequest> rejectRequest(String requestId, {String? reason});
  Future<DepartmentRequest> startRequest(String requestId);
  Future<DepartmentRequest> completeRequest(String requestId);
}
