import 'employee_contact.dart';

enum ConversationStatus {
  active,
  archived,
}

class Conversation {
  final String id;
  final List<String> participantIds;
  final String departmentId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final ConversationStatus status;
  final EmployeeContact? otherParticipant;

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.departmentId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.status = ConversationStatus.active,
    this.otherParticipant,
  });

  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    String? departmentId,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    ConversationStatus? status,
    EmployeeContact? otherParticipant,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      departmentId: departmentId ?? this.departmentId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status ?? this.status,
      otherParticipant: otherParticipant ?? this.otherParticipant,
    );
  }
}
