import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;
  final ScrollController scrollController;

  const MessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.isMe(currentUserId);
        return MessageBubble(
          message: message,
          isMe: isMe,
        );
      },
    );
  }
}
