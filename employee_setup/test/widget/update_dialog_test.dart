import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:employee_setup/core/update/domain/entities/app_version.dart';
import 'package:employee_setup/core/update/domain/entities/update_info.dart';
import 'package:employee_setup/core/update/presentation/widgets/update_dialog.dart';
import 'package:employee_setup/core/update/presentation/widgets/update_banner.dart';
import 'package:employee_setup/core/localization/app_localizations.dart';
import 'package:employee_setup/core/storage/local_storage.dart';
import 'package:employee_setup/app/app_providers.dart';

class TestStorage implements LocalStorage {
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

Widget createUpdateTestHarness(Widget child, {Locale locale = const Locale('ar')}) {
  final storage = TestStorage();
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
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
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('UpdateDialog Widget Tests', () {
    testWidgets('Renders Optional Update Dialog in Arabic with later button', (tester) async {
      const result = UpdateCheckResult(
        hasUpdate: true,
        isForceUpdate: false,
        updateType: UpdateType.normalRelease,
        currentVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 12),
        availableVersion: AppVersion(major: 1, minor: 1, patch: 0, buildNumber: 13),
        config: UpdateConfig(
          latestVersion: AppVersion(major: 1, minor: 1, patch: 0, buildNumber: 13),
          minimumSupportedVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1),
          releaseNotesAr: 'إصلاحات أمنية جديدة',
          releaseNotesEn: 'New security patches',
        ),
      );

      await tester.pumpWidget(
        createUpdateTestHarness(
          const UpdateDialog(checkResult: result),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();

      expect(find.text('تحديث جديد متاح'), findsOneWidget);
      expect(find.text('تحديث الآن'), findsOneWidget);
      expect(find.text('لاحقًا'), findsOneWidget);
      expect(find.text('إصلاحات أمنية جديدة'), findsOneWidget);
    });

    testWidgets('Renders Force Update Dialog without later button', (tester) async {
      const result = UpdateCheckResult(
        hasUpdate: true,
        isForceUpdate: true,
        updateType: UpdateType.normalRelease,
        currentVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 12),
        availableVersion: AppVersion(major: 2, minor: 0, patch: 0, buildNumber: 20),
        config: UpdateConfig(
          latestVersion: AppVersion(major: 2, minor: 0, patch: 0, buildNumber: 20),
          minimumSupportedVersion: AppVersion(major: 2, minor: 0, patch: 0, buildNumber: 15),
          forceUpdate: true,
        ),
      );

      await tester.pumpWidget(
        createUpdateTestHarness(
          const UpdateDialog(checkResult: result),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();

      expect(find.text('تحديث جديد متاح'), findsOneWidget);
      expect(find.text('تحديث الآن'), findsOneWidget);
      expect(find.text('لاحقًا'), findsNothing);
      expect(find.text('هذا التحديث إلزامي لمتابعة استخدام التطبيق'), findsOneWidget);
    });
  });

  group('UpdateBanner Widget Tests', () {
    testWidgets('Renders Up to date banner when configured', (tester) async {
      await tester.pumpWidget(
        createUpdateTestHarness(
          const UpdateBanner(showIfUpToDate: true),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();

      expect(find.byType(UpdateBanner), findsOneWidget);
    });
  });
}
