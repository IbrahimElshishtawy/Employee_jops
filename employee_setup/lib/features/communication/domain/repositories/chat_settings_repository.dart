import '../entities/chat_settings.dart';

abstract class ChatSettingsRepository {
  /// Loads global chat settings from persistent storage.
  Future<ChatSettings> getSettings();

  /// Persists updated global chat settings.
  Future<void> saveSettings(ChatSettings settings);

  /// Retrieves calculated storage usage for chat data.
  Future<ChatStorageBreakdown> getStorageUsage();

  /// Clears temporary cache safely without touching account or credentials.
  Future<bool> clearCache();

  /// Retrieves per-conversation custom settings.
  Future<ConversationCustomSettings> getConversationSettings(String conversationId);

  /// Saves per-conversation custom settings.
  Future<void> saveConversationSettings(ConversationCustomSettings settings);

  /// Clears message history for a specific conversation.
  Future<void> clearConversationMessages(String conversationId);

  /// Deletes a conversation from local/remote data.
  Future<void> deleteConversation(String conversationId);
}
