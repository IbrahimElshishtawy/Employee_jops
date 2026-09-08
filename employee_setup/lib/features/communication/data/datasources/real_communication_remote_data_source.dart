import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/secure_logger.dart';
import '../models/conversation_model.dart';
import '../models/department_model.dart';
import '../models/department_request_model.dart';
import '../models/employee_contact_model.dart';
import '../models/message_model.dart';
import '../models/request_type_model.dart';
import 'communication_remote_data_source.dart';

class RealCommunicationRemoteDataSource implements CommunicationRemoteDataSource {
  final ApiClient apiClient;

  const RealCommunicationRemoteDataSource(this.apiClient);

  @override
  Future<List<DepartmentModel>> getDepartments() async {
    return const [
      DepartmentModel(
        id: 'dept-hr',
        nameAr: 'الموارد البشرية',
        nameEn: 'Human Resources',
        iconName: 'people',
        isAvailable: true,
      ),
      DepartmentModel(
        id: 'dept-it',
        nameAr: 'تقنية المعلومات',
        nameEn: 'IT Support',
        iconName: 'computer',
        isAvailable: true,
      ),
      DepartmentModel(
        id: 'dept-finance',
        nameAr: 'الحسابات والمالية',
        nameEn: 'Finance & Payroll',
        iconName: 'payments',
        isAvailable: true,
      ),
    ];
  }

  @override
  Future<DepartmentModel?> getDepartmentById(String departmentId) async {
    final depts = await getDepartments();
    return depts.where((d) => d.id == departmentId).firstOrNull;
  }

  @override
  Future<List<EmployeeContactModel>> getAllowedContacts({required String departmentId}) async {
    return [
      EmployeeContactModel(
        id: 'contact-1',
        name: 'مسؤول الموارد البشرية',
        jobTitle: 'HR Specialist',
        departmentId: departmentId,
        departmentName: 'HR',
        isAvailable: true,
      ),
    ];
  }

  @override
  Future<EmployeeContactModel?> getContactById(String contactId) async {
    return EmployeeContactModel(
      id: contactId,
      name: 'مسؤول التواصل',
      jobTitle: 'Representative',
      departmentId: 'dept-hr',
      departmentName: 'HR',
      isAvailable: true,
    );
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.conversations,
        fromData: (data) {
          if (data is List) {
            return data.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <ConversationModel>[];
        },
      );
      return response.data ?? [];
    } on ApiException catch (e) {
      SecureLogger.error('RealCommunicationRemoteDataSource', 'Get conversations error', e);
      return [];
    }
  }

  @override
  Future<ConversationModel> getOrCreateConversation({
    required String recipientId,
    required String departmentId,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.conversations,
        data: {'participantId': recipientId, 'departmentId': departmentId},
        fromData: (data) => ConversationModel.fromJson(data as Map<String, dynamic>),
      );
      if (response.data != null) return response.data!;
    } catch (_) {}

    return ConversationModel(
      id: 'conv-$recipientId',
      participantId: recipientId,
      participantName: 'زميل العمل',
      participantJobTitle: 'موظف',
      departmentId: departmentId,
      departmentName: 'Department',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
      isOnline: true,
    );
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.conversationMessages(conversationId),
        fromData: (data) {
          if (data is List) {
            return data.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <MessageModel>[];
        },
      );
      return response.data ?? [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.conversationMessages(conversationId),
        data: {'receiverId': receiverId, 'content': content},
        fromData: (data) => MessageModel.fromJson(data as Map<String, dynamic>),
      );
      if (response.data != null) return response.data!;
    } catch (_) {}

    return MessageModel(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'ME',
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await apiClient.post(ApiEndpoints.readConversation(conversationId));
    } catch (_) {}
  }

  @override
  Future<List<RequestTypeModel>> getRequestTypes({String? departmentId}) async {
    return const [
      RequestTypeModel(
        id: 'rt-1',
        nameAr: 'طلب تعريف بالراتب',
        nameEn: 'Salary Certificate',
        departmentId: 'dept-hr',
        description: 'شهادة إثبات راتب رسمية موجهة لجهة محددة',
      ),
    ];
  }

  @override
  Future<List<DepartmentRequestModel>> getMyRequests() async {
    return [];
  }

  @override
  Future<List<DepartmentRequestModel>> getDepartmentRequests(String departmentId) async {
    return [];
  }

  @override
  Future<DepartmentRequestModel?> getRequestById(String requestId) async {
    return null;
  }

  @override
  Future<DepartmentRequestModel> createDepartmentRequest(DepartmentRequestModel request) async {
    return request;
  }

  @override
  Future<DepartmentRequestModel> updateRequestStatus({
    required String requestId,
    required String status,
    String? reason,
  }) async {
    throw UnimplementedError();
  }
}
