import '../entities/message.dart';
import '../repositories/communication_repository.dart';

class GetMessages {
  final CommunicationRepository repository;

  GetMessages(this.repository);

  Future<List<Message>> call(String conversationId) async {
    return await repository.getMessages(conversationId);
  }
}
