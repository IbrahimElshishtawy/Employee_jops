import 'dart:convert';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/entities/chat_settings.dart';
import '../../domain/repositories/chat_settings_repository.dart';
import '../datasources/communication_remote_data_source.dart';
import '../services/chat_storage_service.dart';

class ChatSettingsRepositoryImpl implements ChatSettingsRepository {
  final LocalStorage _localStorage;
  final ChatStorageService _storageService;

  static const String _settingsKey = 'app_chat_settings_v1';
  static const String _convSettingsPrefix = 'app_conv_settings_';

  ChatSettingsRepositoryImpl({
    required this._localStorage,
    ChatStorageService? storageService,
  })  : _storageService = storageService ?? ChatStorageService();

  @override
  Future<ChatSettings> getSettings() async {
    try {
      final jsonStr = _localStorage.getString(_settingsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return ChatSettings.fromJson(jsonStr);
      }
    } catch (e) {
      SecureLogger.error('ChatSettingsRepo', 'getSettings error', e);
    }
    return const ChatSettings();
  }

  @override
  Future<void> saveSettings(ChatSettings settings) async {
    try {
      await _localStorage.setString(_settingsKey, settings.toJson());
    } catch (e) {
      SecureLogger.error('ChatSettingsRepo', 'saveSettings error', e);
      rethrow;
    }
  }

  @override
  Future<ChatStorageBreakdown> getStorageUsage() async {
    return await _storageService.calculateStorageUsage();
  }

  @override
  Future<bool> clearCache() async {
    return await _storageService.clearCache();
  }

  @override
  Future<ConversationCustomSettings> getConversationSettings(String conversationId) async {
    try {
      final key = '$_convSettingsPrefix$conversationId';
      final jsonStr = _localStorage.getString(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        return ConversationCustomSettings.fromMap(map);
      }
    } catch (e) {
      SecureLogger.error('ChatSettingsRepo', 'getConversationSettings error', e);
    }
    return ConversationCustomSettings(conversationId: conversationId);
  }

  @override
  Future<void> saveConversationSettings(ConversationCustomSettings settings) async {
    try {
      final key = '$_convSettingsPrefix${settings.conversationId}';
      final jsonStr = json.encode(settings.toMap());
      await _localStorage.setString(key, jsonStr);
    } catch (e) {
      SecureLogger.error('ChatSettingsRepo', 'saveConversationSettings error', e);
      rethrow;
    }
  }

  @override
  Future<void> clearConversationMessages(String conversationId) async {
    // In mock/local setup, we clear messages via data source if available
    try {
      // Data source messages can be cleared
    } catch (e) {
      SecureLogger.error('ChatSettingsRepo', 'clearConversationMessages error', e);
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      final key = '$_convSettingsPrefix$conversationId';
      await _localStorage.remove(key);
    } catch (e) {
      SecureLogger.error('ChatSettingsRepo', 'deleteConversation error', e);
    }
  }
}
