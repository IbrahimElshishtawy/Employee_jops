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
import '../../domain/entities/message.dart';
import '../../domain/entities/employee_contact.dart';
import 'communication_remote_data_source.dart';

class RealCommunicationRemoteDataSource implements CommunicationRemoteDataSource {
  final ApiClient apiClient;

  const RealCommunicationRemoteDataSource(this.apiClient);

  @override
  Future<List<DepartmentModel>> getDepartments() async {
    return const [
      DepartmentModel(
        id: 'SECURITY',
        nameAr: 'الأمن والحراسة',
        nameEn: 'Security & Safety',
        iconName: 'security',
        availableEmployeesCount: 4,
        totalEmployeesCount: 6,
      ),
      DepartmentModel(
        id: 'HOUSEKEEPING',
        nameAr: 'خدمة الغرف والنظافة',
        nameEn: 'Housekeeping',
        iconName: 'cleaning_services',
        availableEmployeesCount: 8,
        totalEmployeesCount: 12,
      ),
      DepartmentModel(
        id: 'ENGINEERING',
        nameAr: 'الهندسة والصيانة',
        nameEn: 'Engineering & Maintenance',
        iconName: 'engineering',
        availableEmployeesCount: 3,
        totalEmployeesCount: 5,
      ),
      DepartmentModel(
        id: 'FRONT_OFFICE',
        nameAr: 'المكاتب الأمامية والاستقبال',
        nameEn: 'Front Office & Reception',
        iconName: 'room_service',
        availableEmployeesCount: 5,
        totalEmployeesCount: 7,
      ),
      DepartmentModel(
        id: 'dept-hr',
        nameAr: 'الموارد البشرية',
        nameEn: 'Human Resources',
        iconName: 'people',
        availableEmployeesCount: 3,
        totalEmployeesCount: 5,
      ),
      DepartmentModel(
        id: 'dept-it',
        nameAr: 'تقنية المعلومات',
        nameEn: 'IT Support',
        iconName: 'computer',
        availableEmployeesCount: 2,
        totalEmployeesCount: 4,
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
        fullName: 'مسؤول الموارد البشرية',
        jobTitleAr: 'أخصائي موارد بشرية',
        jobTitleEn: 'HR Specialist',
        departmentId: departmentId,
        departmentNameAr: 'الموارد البشرية',
        departmentNameEn: 'HR',
        isOnline: true,
        availability: EmployeeAvailability.available,
      ),
    ];
  }

  @override
  Future<EmployeeContactModel?> getContactById(String contactId) async {
    final contacts = await getAllowedContacts(departmentId: 'dept-hr');
    return contacts.where((c) => c.id == contactId).firstOrNull;
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
      id: 'conv-${DateTime.now().millisecondsSinceEpoch}',
      participantIds: [recipientId],
      departmentId: departmentId,
      unreadCount: 0,
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
      senderName: 'Me',
      receiverId: receiverId,
      content: content,
      createdAt: DateTime.now(),
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
        descriptionAr: 'شهادة إثبات راتب رسمية موجهة لجهة محددة',
        descriptionEn: 'Official salary certificate',
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
