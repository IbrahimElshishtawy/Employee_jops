import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.senderName,
    required super.receiverId,
    required super.content,
    required super.createdAt,
    super.status,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    MessageStatus parseStatus(String? val) {
      switch (val?.toLowerCase()) {
        case 'sending':
          return MessageStatus.sending;
        case 'sent':
          return MessageStatus.sent;
        case 'delivered':
          return MessageStatus.delivered;
        case 'read':
          return MessageStatus.read;
        case 'failed':
          return MessageStatus.failed;
        default:
          return MessageStatus.sent;
      }
    }

    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String? ?? json['conversation_id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? json['sender_id'] as String? ?? '',
      senderName: json['senderName'] as String? ?? json['sender_name'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? json['receiver_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      status: parseStatus(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory MessageModel.fromEntity(Message entity) {
    return MessageModel(
      id: entity.id,
      conversationId: entity.conversationId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      receiverId: entity.receiverId,
      content: entity.content,
      createdAt: entity.createdAt,
      status: entity.status,
    );
  }
}
