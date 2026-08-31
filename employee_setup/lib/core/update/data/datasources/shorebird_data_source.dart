import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../../../utils/secure_logger.dart';

abstract class ShorebirdDataSource {
  bool get isShorebirdAvailable;
  Future<int?> getCurrentPatchNumber();
  Future<bool> isPatchAvailable();
  Future<bool> downloadAndInstallPatch();
}

class ShorebirdDataSourceImpl implements ShorebirdDataSource {
  final ShorebirdUpdater _updater;

  ShorebirdDataSourceImpl({ShorebirdUpdater? updater})
      : _updater = updater ?? ShorebirdUpdater();

  @override
  bool get isShorebirdAvailable {
    try {
      return _updater.isAvailable;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int?> getCurrentPatchNumber() async {
    if (!isShorebirdAvailable) return null;
    try {
      final patch = await _updater.readCurrentPatch();
      return patch?.number;
    } catch (e) {
      SecureLogger.info('ShorebirdDataSource', 'readCurrentPatch: $e');
      return null;
    }
  }

  @override
  Future<bool> isPatchAvailable() async {
    if (!isShorebirdAvailable) return false;
    try {
      final status = await _updater.checkForUpdate();
      return status == UpdateStatus.outdated;
    } catch (e) {
      SecureLogger.info('ShorebirdDataSource', 'checkForUpdate: $e');
      return false;
    }
  }

  @override
  Future<bool> downloadAndInstallPatch() async {
    if (!isShorebirdAvailable) return false;
    try {
      await _updater.update();
      SecureLogger.info('ShorebirdDataSource', 'Shorebird patch downloaded successfully');
      return true;
    } catch (e) {
      SecureLogger.error('ShorebirdDataSource', 'downloadAndInstallPatch failed', e);
      return false;
    }
  }
}
