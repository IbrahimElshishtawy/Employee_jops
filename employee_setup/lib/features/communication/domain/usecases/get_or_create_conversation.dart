import '../entities/conversation.dart';
import '../repositories/communication_repository.dart';

class GetOrCreateConversation {
  final CommunicationRepository repository;

  GetOrCreateConversation(this.repository);

  Future<Conversation> call({
    required String recipientId,
    required String departmentId,
  }) async {
    return await repository.getOrCreateConversation(
      recipientId: recipientId,
      departmentId: departmentId,
    );
  }
}
