import 'package:flutter_test/flutter_test.dart';
import 'package:employee_setup/features/communication/domain/entities/chat_settings.dart';
import 'package:employee_setup/features/communication/data/repositories/chat_settings_repository_impl.dart';
import 'package:employee_setup/features/communication/presentation/providers/chat_settings_provider.dart';
import 'package:employee_setup/core/storage/local_storage.dart';

class MockLocalStorage implements LocalStorage {
  final Map<String, dynamic> _store = {};

  @override
  Future<void> init() async {}

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => _store[key] as bool?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _store[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => _store[key] as int?;

  @override
  Future<bool> setInt(String key, int value) async {
    _store[key] = value;
    return true;
  }

  @override
  double? getDouble(String key) => _store[key] as double?;

  @override
  Future<bool> setDouble(String key, double value) async {
    _store[key] = value;
    return true;
  }

  @override
  List<String>? getStringList(String key) => _store[key] as List<String>?;

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _store[key] = value;
    return true;
  }

  @override
  bool containsKey(String key) => _store.containsKey(key);

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _store.clear();
    return true;
  }
}

void main() {
  group('ChatSettings Entity & Defaults', () {
    test('Default values follow requirements', () {
      const settings = ChatSettings();
      expect(settings.messageNotifications, isTrue);
      expect(settings.messageSound, isTrue);
      expect(settings.vibration, isTrue);
      expect(settings.messagePreview, isTrue);
      expect(settings.showOnlineStatus, isTrue);
      expect(settings.showLastSeen, isTrue);
      expect(settings.typingIndicator, isTrue);
      expect(settings.readReceipts, isTrue);
      expect(settings.autoDownloadImages, isTrue);
      expect(settings.autoDownloadVideos, isFalse);
      expect(settings.wifiOnly, isFalse);
      expect(settings.mediaQuality, equals(ChatMediaQuality.standard));
      expect(settings.biometricChatLock, isFalse);
      expect(settings.hideMessagePreview, isFalse);
    });

    test('toJson and fromJson preserves all properties', () {
      final original = const ChatSettings().copyWith(
        messageNotifications: false,
        autoDownloadVideos: true,
        mediaQuality: ChatMediaQuality.high,
        biometricChatLock: true,
      );

      final jsonStr = original.toJson();
      final restored = ChatSettings.fromJson(jsonStr);

      expect(restored.messageNotifications, isFalse);
      expect(restored.autoDownloadVideos, isTrue);
      expect(restored.mediaQuality, equals(ChatMediaQuality.high));
      expect(restored.biometricChatLock, isTrue);
    });

    test('ChatStorageBreakdown formatBytes formats properly', () {
      expect(ChatStorageBreakdown.formatBytes(0), '0 B');
      expect(ChatStorageBreakdown.formatBytes(1024), '1 KB');
      expect(ChatStorageBreakdown.formatBytes(1024 * 1024 * 5), '5 MB');
    });
  });

  group('ChatSettingsRepositoryImpl & Notifier', () {
    late MockLocalStorage storage;
    late ChatSettingsRepositoryImpl repository;

    setUp(() {
      storage = MockLocalStorage();
      repository = ChatSettingsRepositoryImpl(localStorage: storage);
    });

    test('Saving and retrieving chat settings works', () async {
      final initial = await repository.getSettings();
      expect(initial.messageNotifications, isTrue);

      final modified = initial.copyWith(showOnlineStatus: false);
      await repository.saveSettings(modified);

      final fetched = await repository.getSettings();
      expect(fetched.showOnlineStatus, isFalse);
    });

    test('Notifier optimistic update and persistence', () async {
      final notifier = ChatSettingsNotifier(repository);
      await notifier.toggleMessageSound(false);
      expect(notifier.state.messageSound, isFalse);

      await notifier.setMediaQuality(ChatMediaQuality.original);
      expect(notifier.state.mediaQuality, equals(ChatMediaQuality.original));

      final persisted = await repository.getSettings();
      expect(persisted.mediaQuality, equals(ChatMediaQuality.original));
    });

    test('Per conversation custom settings persistence', () async {
      final notifier = ConversationSettingsNotifier(repository, 'conv-test-1');
      expect(notifier.state.isMuted, isFalse);

      await notifier.toggleMute(true);
      expect(notifier.state.isMuted, isTrue);

      await notifier.togglePin(true);
      expect(notifier.state.isPinned, isTrue);

      final stored = await repository.getConversationSettings('conv-test-1');
      expect(stored.isMuted, isTrue);
      expect(stored.isPinned, isTrue);
    });
  });
}
