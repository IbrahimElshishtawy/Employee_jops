import '../entities/app_version.dart';
import '../entities/update_info.dart';

abstract class UpdateService {
  /// Initializes update checking infrastructure and Shorebird updater.
  Future<void> initialize();

  /// Checks for available updates (combining Store version and Shorebird patches).
  Future<UpdateCheckResult> checkForUpdate({bool isManualCheck = false});

  /// Checks specifically if a Shorebird OTA patch is available for the current release.
  Future<bool> checkForShorebirdPatch();

  /// Downloads and stages the latest Shorebird patch.
  Future<bool> downloadAndApplyShorebirdPatch();

  /// Handles incoming push notification payloads with type 'app_update'.
  Future<void> handleUpdateNotification(Map<String, dynamic> data);

  /// Launches the store / GitHub release download URL.
  Future<bool> openStoreOrReleaseUrl(String? customUrl);

  /// Returns the current installed binary version.
  AppVersion get currentInstalledVersion;

  /// Returns the current active Shorebird patch number if available.
  int? get currentShorebirdPatchNumber;
}
