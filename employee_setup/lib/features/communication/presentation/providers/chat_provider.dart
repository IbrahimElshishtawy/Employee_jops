import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/mock/models/hr_message.dart';
import '../../../notifications/domain/models/app_notification.dart';
import '../../domain/entities/message.dart';
import 'communication_providers.dart';
import 'conversations_provider.dart';

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final String conversationId;

  ChatNotifier(this._ref, this.conversationId) : super(const ChatState()) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final getMessages = _ref.read(getMessagesUseCaseProvider);
      final messages = await getMessages(conversationId);
      final repo = _ref.read(communicationRepositoryProvider);
      await repo.markConversationAsRead(conversationId);
      state = state.copyWith(messages: messages, isLoading: false);
      _ref.invalidate(conversationsListProvider);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return false;

    state = state.copyWith(isSending: true);
    try {
      final sendMsg = _ref.read(sendMessageUseCaseProvider);
      final newMsg = await sendMsg(
        conversationId: conversationId,
        receiverId: receiverId,
        content: content.trim(),
      );

      final updatedList = List<Message>.from(state.messages)..add(newMsg);
      state = state.copyWith(messages: updatedList, isSending: false);

      // Invalidate conversations list to show new last message
      _ref.invalidate(conversationsListProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>((ref, conversationId) {
  return ChatNotifier(ref, conversationId);
});
