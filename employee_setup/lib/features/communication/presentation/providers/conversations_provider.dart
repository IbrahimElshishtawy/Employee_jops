import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/conversation.dart';
import 'communication_providers.dart';

final conversationsListProvider = FutureProvider<List<Conversation>>((ref) async {
  final getConversations = ref.watch(getConversationsUseCaseProvider);
  return await getConversations();
});
