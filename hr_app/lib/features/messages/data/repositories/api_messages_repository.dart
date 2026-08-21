import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/message_entity.dart';

/// Production Live API Messages Repository
class ApiMessagesRepository implements MessagesRepository {
  final ApiClient _apiClient;

  ApiMessagesRepository(this._apiClient);

  @override
  Future<PaginatedList<ConversationEntity>> getConversations(ConversationFilter filter) async {
    try {
      final queryParams = <String, String>{
        'page': filter.page.toString(),
        'pageSize': filter.pageSize.toString(),
      };
      if (filter.searchQuery != null) queryParams['q'] = filter.searchQuery!;
      if (filter.onlyUnread == true) queryParams['unread'] = 'true';
      if (filter.department != null) queryParams['department'] = filter.department!;
      if (filter.status != null) queryParams['status'] = filter.status!.name;

      final response = await _apiClient.get(
        '${ApiEndpoints.messages}/conversations',
        queryParams: queryParams,
        parser: (data) {
          final json = data as Map<String, dynamic>;
          final rawList = (json['items'] as List<dynamic>?) ?? [];
          final items = rawList.map((e) => _mapConversation(e as Map<String, dynamic>)).toList();

          return PaginatedList<ConversationEntity>(
            items: items,
            totalCount: json['totalCount'] as int? ?? items.length,
            page: json['page'] as int? ?? filter.page,
            pageSize: json['pageSize'] as int? ?? filter.pageSize,
            totalPages: json['totalPages'] as int? ?? 1,
          );
        },
      );

      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<ConversationEntity> getConversationById(String conversationId) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.messages}/conversations/$conversationId',
        parser: (data) => _mapConversation(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String conversationId, {int limit = 50}) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.messages}/conversations/$conversationId/messages',
        queryParams: {'limit': limit.toString()},
        parser: (data) {
          final list = (data as List<dynamic>?) ?? [];
          return list.map((e) => _mapMessage(e as Map<String, dynamic>)).toList();
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<ChatMessageEntity> sendMessage(String conversationId, String content) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.messages}/conversations/$conversationId/messages',
        body: {'content': content},
        parser: (data) => _mapMessage(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<ConversationEntity> startConversation(String employeeId, String initialMessage) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.messages}/conversations',
        body: {
          'employeeId': employeeId,
          'message': initialMessage,
        },
        parser: (data) => _mapConversation(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _apiClient.post('${ApiEndpoints.messages}/conversations/$conversationId/read');
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<MessagesKpiSummary> getMessagesKpis() async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.messages}/kpis',
        parser: (data) {
          final json = data as Map<String, dynamic>;
          return MessagesKpiSummary(
            totalConversations: json['totalConversations'] as int? ?? 0,
            activeUnreadConversations: json['activeUnreadConversations'] as int? ?? 0,
            totalUnreadMessages: json['totalUnreadMessages'] as int? ?? 0,
            resolvedConversations: json['resolvedConversations'] as int? ?? 0,
          );
        },
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  static ConversationEntity _mapConversation(Map<String, dynamic> map) {
    return ConversationEntity(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      employeeCode: map['employeeCode'] as String? ?? '',
      employeeDepartment: map['employeeDepartment'] as String? ?? '',
      employeeJobTitle: map['employeeJobTitle'] as String? ?? '',
      employeeWorkplace: map['employeeWorkplace'] as String?,
      employeeAvatarUrl: map['employeeAvatarUrl'] as String?,
      lastMessageContent: map['lastMessageContent'] as String? ?? '',
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.parse(map['lastMessageTime'] as String)
          : DateTime.now(),
      lastMessageSenderType: _parseSenderType(map['lastMessageSenderType'] as String?),
      unreadCount: map['unreadCount'] as int? ?? 0,
      status: _parseStatus(map['status'] as String?),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  static ChatMessageEntity _mapMessage(Map<String, dynamic> map) {
    return ChatMessageEntity(
      id: map['id'] as String,
      conversationId: map['conversationId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderType: _parseSenderType(map['senderType'] as String?),
      content: map['content'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  static MessageSenderType _parseSenderType(String? str) {
    switch (str?.toLowerCase()) {
      case 'hr':
        return MessageSenderType.hr;
      case 'system':
        return MessageSenderType.system;
      default:
        return MessageSenderType.employee;
    }
  }

  static ConversationStatus _parseStatus(String? str) {
    switch (str?.toLowerCase()) {
      case 'resolved':
        return ConversationStatus.resolved;
      case 'archived':
        return ConversationStatus.archived;
      default:
        return ConversationStatus.open;
    }
  }
}
