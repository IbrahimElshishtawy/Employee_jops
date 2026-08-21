import '../../../employees/domain/entities/employee_entity.dart';

enum MessageSenderType { hr, employee, system }

enum ConversationStatus {
  open('Open'),
  resolved('Resolved'),
  archived('Archived');

  final String label;
  const ConversationStatus(this.label);
}

/// Single chat message in a conversation thread
class ChatMessageEntity {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final MessageSenderType senderType;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  ChatMessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    MessageSenderType? senderType,
    String? content,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Conversation summary entity for the inbox list
class ConversationEntity {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String employeeDepartment;
  final String employeeJobTitle;
  final String? employeeWorkplace;
  final String? employeeAvatarUrl;
  final String lastMessageContent;
  final DateTime lastMessageTime;
  final MessageSenderType lastMessageSenderType;
  final int unreadCount;
  final ConversationStatus status;
  final DateTime createdAt;

  const ConversationEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.employeeDepartment,
    required this.employeeJobTitle,
    this.employeeWorkplace,
    this.employeeAvatarUrl,
    required this.lastMessageContent,
    required this.lastMessageTime,
    required this.lastMessageSenderType,
    this.unreadCount = 0,
    this.status = ConversationStatus.open,
    required this.createdAt,
  });

  ConversationEntity copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    String? employeeDepartment,
    String? employeeJobTitle,
    String? employeeWorkplace,
    String? employeeAvatarUrl,
    String? lastMessageContent,
    DateTime? lastMessageTime,
    MessageSenderType? lastMessageSenderType,
    int? unreadCount,
    ConversationStatus? status,
    DateTime? createdAt,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeDepartment: employeeDepartment ?? this.employeeDepartment,
      employeeJobTitle: employeeJobTitle ?? this.employeeJobTitle,
      employeeWorkplace: employeeWorkplace ?? this.employeeWorkplace,
      employeeAvatarUrl: employeeAvatarUrl ?? this.employeeAvatarUrl,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderType: lastMessageSenderType ?? this.lastMessageSenderType,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Aggregated KPI summary for messages
class MessagesKpiSummary {
  final int totalConversations;
  final int activeUnreadConversations;
  final int totalUnreadMessages;
  final int resolvedConversations;

  const MessagesKpiSummary({
    required this.totalConversations,
    required this.activeUnreadConversations,
    required this.totalUnreadMessages,
    required this.resolvedConversations,
  });
}

class ConversationFilter {
  final String? searchQuery;
  final bool? onlyUnread;
  final String? department;
  final ConversationStatus? status;
  final int page;
  final int pageSize;

  const ConversationFilter({
    this.searchQuery,
    this.onlyUnread,
    this.department,
    this.status,
    this.page = 1,
    this.pageSize = 20,
  });
}

abstract class MessagesRepository {
  Future<PaginatedList<ConversationEntity>> getConversations(ConversationFilter filter);
  Future<ConversationEntity> getConversationById(String conversationId);
  Future<List<ChatMessageEntity>> getMessages(String conversationId, {int limit = 50});
  Future<ChatMessageEntity> sendMessage(String conversationId, String content);
  Future<ConversationEntity> startConversation(String employeeId, String initialMessage);
  Future<void> markConversationAsRead(String conversationId);
  Future<MessagesKpiSummary> getMessagesKpis();
}
