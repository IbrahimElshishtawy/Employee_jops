enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  bool isMe(String currentUserId) => senderId == currentUserId;

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
