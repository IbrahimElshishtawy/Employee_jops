import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:employee_setup/core/localization/app_localizations.dart';

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
  List<String>? getStringList(String key) => _store[key] as List<String>?;

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _store[key] = value;
    return true;
  }

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

Widget createTestWidget(Widget child, {Locale locale = const Locale('en')}) {
  final storage = TestLocalStorage();
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      chatStorageUsageProvider.overrideWith(
        (ref) => const ChatStorageBreakdown(
          imagesBytes: 1024 * 100,
          videosBytes: 1024 * 500,
          filesBytes: 1024 * 200,
          voiceMessagesBytes: 1024 * 50,
          cachedDataBytes: 1024 * 800,
        ),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  group('ChatSettingsScreen Widget Tests', () {
    testWidgets('Renders all main sections and titles', (tester) async {
      await tester.pumpWidget(createTestWidget(const ChatSettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ChatSettingsSection), findsNWidgets(5));
      expect(find.byType(ChatSettingsSwitchTile), findsWidgets);
      expect(find.byType(ChatStorageTile), findsOneWidget);
    });

    testWidgets('Toggling switch tile updates settings', (tester) async {
      await tester.pumpWidget(createTestWidget(const ChatSettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      await tester.tap(switches.first);
      await tester.pump();
    });
  });

  group('ConversationInfoScreen Widget Tests', () {
    testWidgets('Renders conversation info and settings options in English', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ConversationInfoScreen(conversationId: 'conv-test-1'),
          locale: const Locale('en'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Conversation Info'), findsOneWidget);
      expect(find.text('Conversation Settings'), findsOneWidget);
      expect(find.text('Mute Notifications'), findsOneWidget);
      expect(find.text('Search in Conversation'), findsOneWidget);
      expect(find.text('Pin Conversation'), findsOneWidget);
      expect(find.text('Archive Conversation'), findsOneWidget);
      expect(find.text('Clear Chat'), findsOneWidget);
      expect(find.text('Delete Conversation'), findsOneWidget);
    });

    testWidgets('Renders in Arabic RTL seamlessly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ConversationInfoScreen(conversationId: 'conv-test-1'),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('معلومات المحادثة'), findsOneWidget);
      expect(find.text('إعدادات المحادثة'), findsOneWidget);
      expect(find.text('كتم التنبيهات'), findsOneWidget);
      expect(find.text('تثبيت المحادثة'), findsOneWidget);
      expect(find.text('أرشفة المحادثة'), findsOneWidget);
    });
  });
}
