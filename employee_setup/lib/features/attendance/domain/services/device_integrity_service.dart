import '../models/device_integrity_result.dart';

/// DeviceIntegrityService defines the interface for obtaining hardware-backed device
/// and app integrity attestations (Play Integrity on Android, App Attest on iOS).
///
/// CRITICAL ARCHITECTURAL PRINCIPLE:
/// - The mobile client DOES NOT decide that an integrity token is valid.
/// - The mobile client acquires the token/assertion using a server-issued nonce/challenge
///   and forwards it to the backend.
/// - The backend independently validates the token against Google/Apple verification APIs.
abstract class DeviceIntegrityService {
  /// Generates a client/server challenge nonce.
  String generateNonce();

  /// Requests a platform device integrity attestation token.
  /// [nonce]: Cryptographic challenge to prevent replay attacks.
  Future<DeviceIntegrityResult> requestIntegrityToken({required String nonce});

  /// Checks if the device integrity feature is supported on the current hardware/OS.
  Future<bool> isSupported();
}
