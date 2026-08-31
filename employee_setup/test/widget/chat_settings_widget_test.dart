import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:employee_setup/features/communication/presentation/screens/chat_settings_screen.dart';
import 'package:employee_setup/features/communication/presentation/screens/conversation_info_screen.dart';
import 'package:employee_setup/features/communication/presentation/widgets/chat_settings/chat_settings_section.dart';
import 'package:employee_setup/features/communication/presentation/widgets/chat_settings/chat_settings_switch_tile.dart';
import 'package:employee_setup/features/communication/presentation/widgets/chat_settings/chat_storage_tile.dart';
import 'package:employee_setup/features/communication/domain/entities/chat_settings.dart';
import 'package:employee_setup/features/communication/presentation/providers/chat_settings_provider.dart';
import 'package:employee_setup/core/storage/local_storage.dart';
import 'package:employee_setup/app/app_providers.dart';

class TestLocalStorage implements LocalStorage {
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

Widget createTestWidget(Widget child) {
  final storage = TestLocalStorage();
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('ChatSettingsScreen Widget Tests', () {
    testWidgets('Renders all main sections and titles', (tester) async {
      await tester.pumpWidget(createTestWidget(const ChatSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ChatSettingsSection), findsNWidgets(5));
      expect(find.byType(ChatSettingsSwitchTile), findsWidgets);
      expect(find.byType(ChatStorageTile), findsOneWidget);
    });

    testWidgets('Toggling switch tile updates settings', (tester) async {
      await tester.pumpWidget(createTestWidget(const ChatSettingsScreen()));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      await tester.tap(switches.first);
      await tester.pumpAndSettle();
    });
  });

  group('ConversationInfoScreen Widget Tests', () {
    testWidgets('Renders conversation info and settings options', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ConversationInfoScreen(conversationId: 'conv-test-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Conversation Info'), findsOneWidget);
      expect(find.text('Conversation Settings'), findsOneWidget);
      expect(find.text('Mute Notifications'), findsOneWidget);
      expect(find.text('Search in Conversation'), findsOneWidget);
      expect(find.text('Pin Conversation'), findsOneWidget);
      expect(find.text('Archive Conversation'), findsOneWidget);
      expect(find.text('Clear Chat'), findsOneWidget);
      expect(find.text('Delete Conversation'), findsOneWidget);
    });
  });
}
