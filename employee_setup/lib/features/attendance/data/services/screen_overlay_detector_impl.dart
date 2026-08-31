import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/services/screen_overlay_detector.dart';

/// Implementation of [ScreenOverlayDetector] that detects active overlay conditions
/// using Android platform capabilities via MethodChannel where available, with safe fallbacks.
class ScreenOverlayDetectorImpl implements ScreenOverlayDetector {
  static const MethodChannel _channel =
      MethodChannel('com.cyberwise.employee/screen_security');

  bool simulatedOverlayDetected;

  ScreenOverlayDetectorImpl({this.simulatedOverlayDetected = false});

  @override
  Future<bool> isUnsafeOverlayDetected() async {
    if (simulatedOverlayDetected) {
      return true;
    }

    if (kIsWeb) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkScreenSecurity');
      if (result != null) {
        final isSafe = result['isSafe'] as bool? ?? true;
        final hasOverlayPermission = result['hasOverlayPermission'] as bool? ?? false;
        // On Android, if not safe or suspicious overlay flag reported
        if (!isSafe) {
          SecureLogger.warn('ScreenOverlayDetectorImpl', 'Unsafe overlay state detected');
          return true;
        }
        SecureLogger.info(
          'ScreenOverlayDetectorImpl',
          'Screen security verified. Overlay permission: $hasOverlayPermission',
        );
        return false;
      }
    } on MissingPluginException {
      // Running on test harness, desktop, or iOS where method channel is not registered
      SecureLogger.info(
        'ScreenOverlayDetectorImpl',
        'MethodChannel com.cyberwise.employee/screen_security not implemented on platform. Defaulting to safe.',
      );
      return false;
    } on PlatformException catch (e) {
      SecureLogger.warn('ScreenOverlayDetectorImpl', 'PlatformException during check: ${e.message}');
      return false;
    } catch (e) {
      SecureLogger.error('ScreenOverlayDetectorImpl', 'Error checking overlay security: $e');
      return false;
    }

    return false;
  }

  /// Enables or disables FLAG_SECURE on the native window.
  Future<bool> setSecureWindowFlag(bool enable) async {
    if (kIsWeb) return false;
    try {
      final res = await _channel.invokeMethod<bool>('setSecureFlag', {'enable': enable});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
