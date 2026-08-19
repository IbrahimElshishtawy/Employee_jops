enum DeviceIntegrityPlatform {
  androidPlayIntegrity,
  iosAppAttest,
  web,
  simulator,
  unknown,
}

enum DeviceIntegrityStatus {
  verified,
  tokenAcquired,
  challengePending,
  unsupported,
  failed,
  simulationMode,
}

/// Representation of the device/app integrity attestation.
/// Note: The client requests and provides the token/challenge proof.
/// The backend is the sole authority that cryptographically validates the token.
class DeviceIntegrityResult {
  final DeviceIntegrityPlatform platform;
  final DeviceIntegrityStatus status;
  final String? token;
  final String? nonce;
  final String? keyId;
  final String? deviceModel;
  final bool isRootedOrJailbroken;
  final bool isEmulator;
  final DateTime timestamp;
  final String? errorMessage;

  const DeviceIntegrityResult({
    required this.platform,
    required this.status,
    this.token,
    this.nonce,
    this.keyId,
    this.deviceModel,
    this.isRootedOrJailbroken = false,
    this.isEmulator = false,
    required this.timestamp,
    this.errorMessage,
  });

  bool get hasToken => token != null && token!.isNotEmpty;
  bool get isSuspicious => isRootedOrJailbroken;

  Map<String, dynamic> toJson() => {
    'platform': platform.name,
    'status': status.name,
    'token': token,
    'nonce': nonce,
    'keyId': keyId,
    'deviceModel': deviceModel,
    'isRootedOrJailbroken': isRootedOrJailbroken,
    'isEmulator': isEmulator,
    'timestamp': timestamp.toIso8601String(),
    'errorMessage': errorMessage,
  };

  factory DeviceIntegrityResult.fromJson(Map<String, dynamic> json) =>
      DeviceIntegrityResult(
        platform: DeviceIntegrityPlatform.values.byName(
          json['platform'] as String? ?? 'unknown',
        ),
        status: DeviceIntegrityStatus.values.byName(
          json['status'] as String? ?? 'unsupported',
        ),
        token: json['token'] as String?,
        nonce: json['nonce'] as String?,
        keyId: json['keyId'] as String?,
        deviceModel: json['deviceModel'] as String?,
        isRootedOrJailbroken: json['isRootedOrJailbroken'] as bool? ?? false,
        isEmulator: json['isEmulator'] as bool? ?? false,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        errorMessage: json['errorMessage'] as String?,
      );
}
