import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../../../../core/utils/secure_logger.dart';
import '../../domain/services/biometric_service.dart';

/// RealBiometricService implements hardware-backed biometric verification
/// using the device operating system's native API (Android BiometricPrompt, iOS Face ID / Touch ID).
///
/// NOTE: The application NEVER accesses or stores biometric templates, fingerprint images,
/// or Face ID representations. Only the platform authentication verdict is received.
class RealBiometricService implements BiometricService {
  final LocalAuthentication _auth;

  RealBiometricService({
    LocalAuthentication? auth,
  }) : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      SecureLogger.error('RealBiometricService', 'isDeviceSupported error', e);
      return false;
    }
  }

  @override
  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      SecureLogger.error('RealBiometricService', 'canCheckBiometrics error', e);
      return false;
    }
  }

  /// Returns list of supported biometric types (e.g. fingerprint, face, iris).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return const [];
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      SecureLogger.error('RealBiometricService', 'getAvailableBiometrics error', e);
      return const [];
    }
  }

  @override
  Future<BiometricAuthResult> authenticate({
    String reason = 'يرجى تأكيد بصمتك لتسجيل الحضور',
  }) async {
    if (kIsWeb) {
      return BiometricAuthResult.notAvailable;
    }

    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        return BiometricAuthResult.notAvailable;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
          biometricOnly: false,
        ),
      );

      return authenticated
          ? BiometricAuthResult.success
          : BiometricAuthResult.failed;
    } on PlatformException catch (e) {
      SecureLogger.warn('RealBiometricService', 'PlatformException code: ${e.code}');
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet) {
        return BiometricAuthResult.notAvailable;
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return BiometricAuthResult.failed;
      } else {
        return BiometricAuthResult.cancelled;
      }
    } catch (e) {
      SecureLogger.error('RealBiometricService', 'authenticate exception', e);
      return BiometricAuthResult.failed;
    }
  }
}
