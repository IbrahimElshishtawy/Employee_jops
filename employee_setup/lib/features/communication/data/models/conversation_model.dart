import '../../domain/entities/conversation.dart';
import 'employee_contact_model.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.participantIds,
    required super.departmentId,
    super.lastMessage,
    super.lastMessageAt,
    super.unreadCount,
    super.status,
    super.otherParticipant,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    ConversationStatus parseStatus(String? val) {
      return val == 'archived' ? ConversationStatus.archived : ConversationStatus.active;
    }

    return ConversationModel(
      id: json['id'] as String,
      participantIds: (json['participantIds'] as List<dynamic>? ??
              json['participant_ids'] as List<dynamic>? ??
              [])
          .map((e) => e.toString())
          .toList(),
      departmentId: json['departmentId'] as String? ?? json['department_id'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? json['last_message'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : (json['last_message_at'] != null
              ? DateTime.tryParse(json['last_message_at'] as String)
              : null),
      unreadCount: json['unreadCount'] as int? ?? json['unread_count'] as int? ?? 0,
      status: parseStatus(json['status'] as String?),
      otherParticipant: json['otherParticipant'] != null
          ? EmployeeContactModel.fromJson(json['otherParticipant'] as Map<String, dynamic>)
          : (json['other_participant'] != null
              ? EmployeeContactModel.fromJson(json['other_participant'] as Map<String, dynamic>)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'departmentId': departmentId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'status': status.name,
      'otherParticipant': otherParticipant != null
          ? EmployeeContactModel.fromEntity(otherParticipant!).toJson()
          : null,
    };
  }

  factory ConversationModel.fromEntity(Conversation entity) {
    return ConversationModel(
      id: entity.id,
      participantIds: entity.participantIds,
      departmentId: entity.departmentId,
      lastMessage: entity.lastMessage,
      lastMessageAt: entity.lastMessageAt,
      unreadCount: entity.unreadCount,
      status: entity.status,
      otherParticipant: entity.otherParticipant,
    );
  }
}
