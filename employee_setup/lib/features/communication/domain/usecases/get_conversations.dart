import '../entities/conversation.dart';
import '../repositories/communication_repository.dart';

class GetConversations {
  final CommunicationRepository repository;

  GetConversations(this.repository);

  Future<List<Conversation>> call() async {
    return await repository.getConversations();
  }
}
