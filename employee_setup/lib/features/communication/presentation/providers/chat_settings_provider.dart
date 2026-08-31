import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../data/repositories/chat_settings_repository_impl.dart';
import '../../domain/entities/chat_settings.dart';
import '../../domain/repositories/chat_settings_repository.dart';

final chatSettingsRepositoryProvider = Provider<ChatSettingsRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  return ChatSettingsRepositoryImpl(
    localStorage: storage,
  );
});

class ChatSettingsNotifier extends StateNotifier<ChatSettings> {
  final ChatSettingsRepository _repository;
  bool _isInitialized = false;

  ChatSettingsNotifier(this._repository) : super(const ChatSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _repository.getSettings();
      if (!_isInitialized) {
        state = settings;
        _isInitialized = true;
      }
    } catch (_) {}
  }

  Future<void> updateSettings(ChatSettings newSettings) async {
    _isInitialized = true;
    final previous = state;
    state = newSettings;
    try {
      await _repository.saveSettings(newSettings);
    } catch (e) {
      state = previous; // Rollback on failure
      rethrow;
    }
  }

  Future<void> toggleMessageNotifications(bool value) async {
    await updateSettings(state.copyWith(messageNotifications: value));
  }

  Future<void> toggleMessageSound(bool value) async {
    await updateSettings(state.copyWith(messageSound: value));
  }

  Future<void> toggleVibration(bool value) async {
    await updateSettings(state.copyWith(vibration: value));
  }

  Future<void> toggleMessagePreview(bool value) async {
    await updateSettings(state.copyWith(messagePreview: value));
  }

  Future<void> toggleShowOnlineStatus(bool value) async {
    await updateSettings(state.copyWith(showOnlineStatus: value));
  }

  Future<void> toggleShowLastSeen(bool value) async {
    await updateSettings(state.copyWith(showLastSeen: value));
  }

  Future<void> toggleTypingIndicator(bool value) async {
    await updateSettings(state.copyWith(typingIndicator: value));
  }

  Future<void> toggleReadReceipts(bool value) async {
    await updateSettings(state.copyWith(readReceipts: value));
  }

  Future<void> toggleAutoDownloadImages(bool value) async {
    await updateSettings(state.copyWith(autoDownloadImages: value));
  }

  Future<void> toggleAutoDownloadVideos(bool value) async {
    await updateSettings(state.copyWith(autoDownloadVideos: value));
  }

  Future<void> toggleWifiOnly(bool value) async {
    await updateSettings(state.copyWith(wifiOnly: value));
  }

  Future<void> setMediaQuality(ChatMediaQuality quality) async {
    await updateSettings(state.copyWith(mediaQuality: quality));
  }

  Future<void> toggleBiometricChatLock(bool value) async {
    await updateSettings(state.copyWith(biometricChatLock: value));
  }

  Future<void> toggleHideMessagePreview(bool value) async {
    await updateSettings(state.copyWith(hideMessagePreview: value));
  }
}

final chatSettingsProvider =
    StateNotifierProvider<ChatSettingsNotifier, ChatSettings>((ref) {
  final repo = ref.watch(chatSettingsRepositoryProvider);
  return ChatSettingsNotifier(repo);
});

final chatStorageUsageProvider =
    FutureProvider.autoDispose<ChatStorageBreakdown>((ref) async {
  final repo = ref.watch(chatSettingsRepositoryProvider);
  return await repo.getStorageUsage();
});

class ConversationSettingsNotifier
    extends StateNotifier<ConversationCustomSettings> {
  final ChatSettingsRepository _repository;
  final String conversationId;
  bool _isInitialized = false;

  ConversationSettingsNotifier(this._repository, this.conversationId)
      : super(ConversationCustomSettings(conversationId: conversationId)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _repository.getConversationSettings(conversationId);
      if (!_isInitialized) {
        state = s;
        _isInitialized = true;
      }
    } catch (_) {}
  }

  Future<void> toggleMute(bool value) async {
    _isInitialized = true;
    final updated = state.copyWith(isMuted: value);
    state = updated;
    await _repository.saveConversationSettings(updated);
  }

  Future<void> togglePin(bool value) async {
    _isInitialized = true;
    final updated = state.copyWith(isPinned: value);
    state = updated;
    await _repository.saveConversationSettings(updated);
  }

  Future<void> toggleArchive(bool value) async {
    _isInitialized = true;
    final updated = state.copyWith(isArchived: value);
    state = updated;
    await _repository.saveConversationSettings(updated);
  }
}

final conversationSettingsProvider = StateNotifierProvider.family<
    ConversationSettingsNotifier,
    ConversationCustomSettings,
    String>((ref, conversationId) {
  final repo = ref.watch(chatSettingsRepositoryProvider);
  return ConversationSettingsNotifier(repo, conversationId);
});
