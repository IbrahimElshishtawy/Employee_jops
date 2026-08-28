import '../models/department_model.dart';
import '../models/employee_contact_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/department_request_model.dart';
import '../models/request_type_model.dart';

/// Contract for Remote Communication API (NestJS backend ready)
///
/// Proposed API Endpoints:
/// GET /api/v1/communication/departments
/// GET /api/v1/communication/departments/:id
/// GET /api/v1/communication/departments/:id/contacts
/// GET /api/v1/communication/contacts/:id
/// GET /api/v1/communication/conversations
/// POST /api/v1/communication/conversations
/// GET /api/v1/communication/conversations/:id/messages
/// POST /api/v1/communication/conversations/:id/messages
/// GET /api/v1/communication/requests
/// POST /api/v1/communication/requests
/// PATCH /api/v1/communication/requests/:id/status
abstract class CommunicationRemoteDataSource {
  Future<List<DepartmentModel>> getDepartments();
  Future<DepartmentModel?> getDepartmentById(String departmentId);
  Future<List<EmployeeContactModel>> getAllowedContacts({required String departmentId});
  Future<EmployeeContactModel?> getContactById(String contactId);
  Future<List<ConversationModel>> getConversations();
  Future<ConversationModel> getOrCreateConversation({
    required String recipientId,
    required String departmentId,
  });
  Future<List<MessageModel>> getMessages(String conversationId);
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  });
  Future<void> markConversationAsRead(String conversationId);
  Future<List<RequestTypeModel>> getRequestTypes({String? departmentId});
  Future<List<DepartmentRequestModel>> getMyRequests();
  Future<List<DepartmentRequestModel>> getDepartmentRequests(String departmentId);
  Future<DepartmentRequestModel?> getRequestById(String requestId);
  Future<DepartmentRequestModel> createDepartmentRequest(DepartmentRequestModel request);
  Future<DepartmentRequestModel> updateRequestStatus({
    required String requestId,
    required String status,
    String? reason,
  });
}
