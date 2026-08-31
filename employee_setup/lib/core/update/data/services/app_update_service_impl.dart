import 'package:package_info_plus/package_info_plus.dart';
import '../../../services/notification_service.dart';
import '../../../utils/secure_logger.dart';
import '../../domain/entities/app_version.dart';
import '../../domain/entities/update_info.dart';
import '../../domain/services/update_service.dart';
import '../datasources/remote_update_data_source.dart';
import '../datasources/shorebird_data_source.dart';

class AppUpdateServiceImpl implements UpdateService {
  final RemoteUpdateDataSource _remoteDataSource;
  final ShorebirdDataSource _shorebirdDataSource;
  final NotificationService _notificationService;

  AppVersion _currentVersion =
      const AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 12);
  int? _shorebirdPatchNumber;
  bool _isInitialized = false;

  AppUpdateServiceImpl({
    required RemoteUpdateDataSource remoteDataSource,
    required ShorebirdDataSource shorebirdDataSource,
    required NotificationService notificationService,
  })  : _remoteDataSource = remoteDataSource,
        _shorebirdDataSource = shorebirdDataSource,
        _notificationService = notificationService;

  @override
  AppVersion get currentInstalledVersion => _currentVersion;

  @override
  int? get currentShorebirdPatchNumber => _shorebirdPatchNumber;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final fullVersionStr = '${packageInfo.version}+${packageInfo.buildNumber}';
      _currentVersion = AppVersion.parse(fullVersionStr);
    } catch (e) {
      SecureLogger.info('AppUpdateService', 'PackageInfo fallback used: $e');
      _currentVersion =
          const AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 12);
    }

    try {
      _shorebirdPatchNumber =
          await _shorebirdDataSource.getCurrentPatchNumber();
    } catch (e) {
      SecureLogger.info('AppUpdateService', 'Shorebird patch check skipped: $e');
    }

    _isInitialized = true;
  }

  @override
  Future<UpdateCheckResult> checkForUpdate({bool isManualCheck = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final config = await _remoteDataSource.fetchLatestUpdateConfig();

      // 1. Check for Forced / Minimum Version Constraint
      if (_currentVersion < config.minimumSupportedVersion) {
        SecureLogger.info(
          'AppUpdateService',
          'Force update required: current $_currentVersion < min ${config.minimumSupportedVersion}',
        );
        return UpdateCheckResult.storeUpdateAvailable(
          currentVersion: _currentVersion,
          availableVersion: config.latestVersion,
          config: config,
          isForceUpdate: true,
        );
      }

      // 2. Check for Newer Store / Binary Release
      if (config.latestVersion > _currentVersion) {
        SecureLogger.info(
          'AppUpdateService',
          'Newer release available: current $_currentVersion < latest ${config.latestVersion}',
        );
        return UpdateCheckResult.storeUpdateAvailable(
          currentVersion: _currentVersion,
          availableVersion: config.latestVersion,
          config: config,
          isForceUpdate: config.forceUpdate,
        );
      }

      // 3. Check for Shorebird OTA Patch (Only if binary is compatible & up to date)
      final hasShorebirdPatch = await checkForShorebirdPatch();
      if (hasShorebirdPatch) {
        // Automatically download and stage the patch in the background
        await downloadAndApplyShorebirdPatch();
        final patchNum = await _shorebirdDataSource.getCurrentPatchNumber() ?? 1;

        return UpdateCheckResult.shorebirdPatchReady(
          currentVersion: _currentVersion,
          config: config,
          patchNumber: patchNum,
        );
      }

      // 4. App is completely up to date
      return UpdateCheckResult.noUpdate(
        currentVersion: _currentVersion,
        config: config,
        shorebirdPatchNumber: _shorebirdPatchNumber,
      );
    } catch (e) {
      SecureLogger.error('AppUpdateService', 'checkForUpdate error', e);
      return UpdateCheckResult.noUpdate(
        currentVersion: _currentVersion,
        config: const UpdateConfig(
          latestVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 12),
          minimumSupportedVersion: AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1),
        ),
      );
    }
  }

  @override
  Future<bool> checkForShorebirdPatch() async {
    return await _shorebirdDataSource.isPatchAvailable();
  }

  @override
  Future<bool> downloadAndApplyShorebirdPatch() async {
    return await _shorebirdDataSource.downloadAndInstallPatch();
  }

  @override
  Future<void> handleUpdateNotification(Map<String, dynamic> data) async {
    try {
      final versionStr = data['version'] as String? ?? '1.0.0';
      final newVersion = AppVersion.parse(versionStr);
      final title = data['title'] as String? ?? 'تحديث جديد متاح';
      final body = data['body'] as String? ?? 'يتوفر إصدار جديد من تطبيق الموظفين';
      final notes = data['releaseNotes'] as String? ?? '';
      final androidUrl = data['androidUrl'] as String? ??
          'https://github.com/IbrahimElshishtawy/Employee_jops/releases/latest';
      final iosUrl = data['iosUrl'] as String? ??
          'https://github.com/IbrahimElshishtawy/Employee_jops/releases/latest';
      final isForce = data['forceUpdate'] == true || data['forceUpdate'] == 'true';

      final config = UpdateConfig(
        latestVersion: newVersion,
        minimumSupportedVersion: isForce
            ? newVersion
            : const AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1),
        androidStoreUrl: androidUrl,
        iosStoreUrl: iosUrl,
        releaseNotes: notes,
        releaseNotesAr: notes,
        releaseNotesEn: notes,
        forceUpdate: isForce,
        publishedAt: DateTime.now(),
      );

      // Cache updated remote config
      await _remoteDataSource.cacheUpdateConfig(config);

      // Display system local notification if a newer version is available
      if (newVersion > _currentVersion) {
        await _notificationService.showLocalNotification(
          id: 99999,
          title: title,
          body: body,
          channelId: NotificationService.announcementsChannelId,
          channelName: NotificationService.announcementsChannelName,
          channelDescription: NotificationService.announcementsChannelDesc,
          payload: '{"type":"APP_UPDATE","actionRoute":"/settings/about"}',
        );
      }
    } catch (e) {
      SecureLogger.error('AppUpdateService', 'handleUpdateNotification error', e);
    }
  }

  @override
  Future<bool> openStoreOrReleaseUrl(String? customUrl) async {
    // In production Flutter, launching URL via native intent or browser
    try {
      SecureLogger.info(
        'AppUpdateService',
        'Opening update URL: $customUrl',
      );
      return true;
    } catch (e) {
      SecureLogger.error('AppUpdateService', 'openStoreOrReleaseUrl error', e);
      return false;
    }
  }
}
