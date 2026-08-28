import '../entities/message.dart';
import '../repositories/communication_repository.dart';

class SendMessage {
  final CommunicationRepository repository;

  SendMessage(this.repository);

  Future<Message> call({
    required String conversationId,
    required String receiverId,
    required String content,
  }) async {
    return await repository.sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      content: content,
    );
  }
}
