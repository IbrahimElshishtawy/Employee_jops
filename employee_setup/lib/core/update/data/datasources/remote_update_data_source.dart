import 'dart:convert';
import '../../../storage/local_storage.dart';
import '../../../utils/secure_logger.dart';
import '../../domain/entities/app_version.dart';
import '../../domain/entities/update_info.dart';

abstract class RemoteUpdateDataSource {
  Future<UpdateConfig> fetchLatestUpdateConfig();
  Future<void> cacheUpdateConfig(UpdateConfig config);
  Future<UpdateConfig?> getCachedUpdateConfig();
}

class RemoteUpdateDataSourceImpl implements RemoteUpdateDataSource {
  final LocalStorage localStorage;
  static const String _cacheKey = 'app_update_remote_config_v1';

  RemoteUpdateDataSourceImpl({required this.localStorage});

  @override
  Future<UpdateConfig> fetchLatestUpdateConfig() async {
    try {
      // 1. Check local storage for dynamic/remote config received via FCM or remote API
      final cached = await getCachedUpdateConfig();
      if (cached != null) {
        return cached;
      }
    } catch (e) {
      SecureLogger.error('RemoteUpdateDataSource', 'fetchLatestUpdateConfig error', e);
    }

    // Default configuration matching application version baseline
    return const UpdateConfig(
      latestVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 12),
      minimumSupportedVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1),
      androidStoreUrl: 'https://github.com/IbrahimElshishtawy/Employee_jops/releases/latest',
      iosStoreUrl: 'https://github.com/IbrahimElshishtawy/Employee_jops/releases/latest',
      releaseNotes: 'تحسينات عامة على الأداء وإصلاحات الاستقرار',
      releaseNotesAr: 'تحسينات عامة على الأداء وإصلاحات الاستقرار',
      releaseNotesEn: 'General performance improvements and stability fixes',
      forceUpdate: false,
    );
  }

  @override
  Future<void> cacheUpdateConfig(UpdateConfig config) async {
    try {
      final jsonStr = json.encode(config.toMap());
      await localStorage.setString(_cacheKey, jsonStr);
    } catch (e) {
      SecureLogger.error('RemoteUpdateDataSource', 'cacheUpdateConfig error', e);
    }
  }

  @override
  Future<UpdateConfig?> getCachedUpdateConfig() async {
    try {
      final jsonStr = localStorage.getString(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        return UpdateConfig.fromMap(map);
      }
    } catch (e) {
      SecureLogger.error('RemoteUpdateDataSource', 'getCachedUpdateConfig error', e);
    }
    return null;
  }
}
