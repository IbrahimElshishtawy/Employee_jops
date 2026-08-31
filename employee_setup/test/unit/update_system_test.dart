import 'package:flutter_test/flutter_test.dart';
import 'package:employee_setup/core/update/domain/entities/app_version.dart';
import 'package:employee_setup/core/update/domain/entities/update_info.dart';
import 'package:employee_setup/core/update/data/datasources/remote_update_data_source.dart';
import 'package:employee_setup/core/update/data/datasources/shorebird_data_source.dart';
import 'package:employee_setup/core/update/data/services/app_update_service_impl.dart';
import 'package:employee_setup/core/services/notification_service.dart';
import 'package:employee_setup/core/storage/local_storage.dart';

class MockTestLocalStorage implements LocalStorage {
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

class FakeRemoteUpdateDataSource implements RemoteUpdateDataSource {
  UpdateConfig config;

  FakeRemoteUpdateDataSource(this.config);

  @override
  Future<UpdateConfig> fetchLatestUpdateConfig() async => config;

  @override
  Future<void> cacheUpdateConfig(UpdateConfig newConfig) async {
    config = newConfig;
  }

  @override
  Future<UpdateConfig?> getCachedUpdateConfig() async => config;
}

class FakeShorebirdDataSource implements ShorebirdDataSource {
  bool available;
  bool patchAvailable;
  int? patchNumber;

  FakeShorebirdDataSource({
    this.available = true,
    this.patchAvailable = false,
    this.patchNumber,
  });

  @override
  bool get isShorebirdAvailable => available;

  @override
  Future<int?> getCurrentPatchNumber() async => patchNumber;

  @override
  Future<bool> isPatchAvailable() async => patchAvailable;

  @override
  Future<bool> downloadAndInstallPatch() async {
    patchNumber = 1;
    patchAvailable = false;
    return true;
  }
}

void main() {
  group('AppVersion Entity & Version Comparison', () {
    test('Correctly parses version strings', () {
      final v1 = AppVersion.parse('1.0.0');
      expect(v1.major, 1);
      expect(v1.minor, 0);
      expect(v1.patch, 0);
      expect(v1.buildNumber, 0);

      final v2 = AppVersion.parse('v1.2.3+45');
      expect(v2.major, 1);
      expect(v2.minor, 2);
      expect(v2.patch, 3);
      expect(v2.buildNumber, 45);
    });

    test('Accurately compares semantic versions', () {
      final v100 = AppVersion.parse('1.0.0');
      final v101 = AppVersion.parse('1.0.1');
      final v110 = AppVersion.parse('1.1.0');
      final v200 = AppVersion.parse('2.0.0');
      final v100b12 = AppVersion.parse('1.0.0+12');
      final v100b13 = AppVersion.parse('1.0.0+13');

      expect(v100 < v101, isTrue);
      expect(v101 < v110, isTrue);
      expect(v110 < v200, isTrue);
      expect(v200 > v100, isTrue);
      expect(v100b12 < v100b13, isTrue);
      expect(v100 == AppVersion.parse('1.0.0'), isTrue);
    });
  });

  group('UpdateConfig Model', () {
    test('Serializes to and from Map', () {
      const config = UpdateConfig(
        latestVersion: AppVersion(major: 1, minor: 2, patch: 0, buildNumber: 15),
        minimumSupportedVersion: AppVersion(major: 1, minor: 1, patch: 0, buildNumber: 10),
        releaseNotesAr: 'إصلاح المشاكل',
        releaseNotesEn: 'Bug fixes',
        forceUpdate: true,
      );

      final map = config.toMap();
      final restored = UpdateConfig.fromMap(map);

      expect(restored.latestVersion, equals(config.latestVersion));
      expect(restored.minimumSupportedVersion, equals(config.minimumSupportedVersion));
      expect(restored.forceUpdate, isTrue);
      expect(restored.localizedNotes(true), 'إصلاح المشاكل');
      expect(restored.localizedNotes(false), 'Bug fixes');
    });
  });

  group('AppUpdateServiceImpl Logic', () {
    late FakeShorebirdDataSource shorebirdDs;
    late FakeRemoteUpdateDataSource remoteDs;
    late NotificationService notificationService;
    late AppUpdateServiceImpl service;

    setUp(() {
      shorebirdDs = FakeShorebirdDataSource();
      remoteDs = FakeRemoteUpdateDataSource(
        const UpdateConfig(
          latestVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 12),
          minimumSupportedVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1),
        ),
      );
      notificationService = NotificationService();
      service = AppUpdateServiceImpl(
        remoteDataSource: remoteDs,
        shorebirdDataSource: shorebirdDs,
        notificationService: notificationService,
      );
    });

    test('Identifies up-to-date state when current matches latest', () async {
      final result = await service.checkForUpdate();
      expect(result.hasUpdate, isFalse);
      expect(result.updateType, equals(UpdateType.none));
    });

    test('Identifies optional store update when newer version exists', () async {
      remoteDs.config = const UpdateConfig(
        latestVersion: AppVersion(major: 1, minor: 1, patch: 0, buildNumber: 14),
        minimumSupportedVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1),
        forceUpdate: false,
      );

      final result = await service.checkForUpdate();
      expect(result.hasUpdate, isTrue);
      expect(result.isForceUpdate, isFalse);
      expect(result.updateType, equals(UpdateType.normalRelease));
      expect(result.availableVersion, equals(const AppVersion(major: 1, minor: 1, patch: 0, buildNumber: 14)));
    });

    test('Identifies force update when current version is below minimumSupportedVersion', () async {
      remoteDs.config = const UpdateConfig(
        latestVersion: AppVersion(major: 2, minor: 0, patch: 0, buildNumber: 20),
        minimumSupportedVersion: AppVersion(major: 1, minor: 5, patch: 0, buildNumber: 15),
        forceUpdate: false,
      );

      final result = await service.checkForUpdate();
      expect(result.hasUpdate, isTrue);
      expect(result.isForceUpdate, isTrue);
      expect(result.updateType, equals(UpdateType.normalRelease));
    });

    test('Identifies and downloads Shorebird OTA patch when available', () async {
      shorebirdDs.patchAvailable = true;

      final result = await service.checkForUpdate();
      expect(result.hasUpdate, isTrue);
      expect(result.updateType, equals(UpdateType.shorebirdPatch));
      expect(result.shorebirdPatchNumber, 1);
    });

    test('Handles FCM update notification payload', () async {
      await service.handleUpdateNotification({
        'type': 'app_update',
        'version': '1.3.0+15',
        'title': 'تحديث جديد',
        'body': 'إصدار جديد متاح',
        'releaseNotes': 'تحسينات',
        'forceUpdate': 'false',
      });

      final cached = await remoteDs.getCachedUpdateConfig();
      expect(cached?.latestVersion, equals(const AppVersion(major: 1, minor: 3, patch: 0, buildNumber: 15)));
    });
  });
}
