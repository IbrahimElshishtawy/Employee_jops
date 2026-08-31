import 'package:flutter/foundation.dart';
import 'app_version.dart';

enum UpdateType {
  /// Major or platform release distributed through Store / GitHub Releases
  normalRelease,

  /// Over-The-Air patch delivered automatically via Shorebird Code Push
  shorebirdPatch,

  /// Application is completely up to date
  none;

  bool get isNormalRelease => this == UpdateType.normalRelease;
  bool get isShorebirdPatch => this == UpdateType.shorebirdPatch;
  bool get isNone => this == UpdateType.none;
}

@immutable
class UpdateConfig {
  final AppVersion latestVersion;
  final AppVersion minimumSupportedVersion;
  final String androidStoreUrl;
  final String iosStoreUrl;
  final String releaseNotes;
  final String? releaseNotesAr;
  final String? releaseNotesEn;
  final bool forceUpdate;
  final DateTime? publishedAt;

  const UpdateConfig({
    required this.latestVersion,
    required this.minimumSupportedVersion,
    this.androidStoreUrl = 'https://github.com/IbrahimElshishtawy/Employee_jops/releases/latest',
    this.iosStoreUrl = 'https://github.com/IbrahimElshishtawy/Employee_jops/releases/latest',
    this.releaseNotes = '',
    this.releaseNotesAr,
    this.releaseNotesEn,
    this.forceUpdate = false,
    this.publishedAt,
  });

  String localizedNotes(bool isArabic) {
    if (isArabic && releaseNotesAr != null && releaseNotesAr!.isNotEmpty) {
      return releaseNotesAr!;
    }
    if (!isArabic && releaseNotesEn != null && releaseNotesEn!.isNotEmpty) {
      return releaseNotesEn!;
    }
    return releaseNotes;
  }

  factory UpdateConfig.fromMap(Map<String, dynamic> map) {
    final latestStr = map['latestVersion'] as String? ?? '1.0.0';
    final minStr = map['minimumSupportedVersion'] as String? ?? '1.0.0';

    return UpdateConfig(
      latestVersion: AppVersion.parse(latestStr),
      minimumSupportedVersion: AppVersion.parse(minStr),
      androidStoreUrl: (map['androidStoreUrl'] as String?) ??
          (map['androidUrl'] as String?) ??
          'https://github.com/IbrahimElshishtawy/Employee_jops/releases/latest',
      iosStoreUrl: (map['iosStoreUrl'] as String?) ??
          (map['iosUrl'] as String?) ??
          'https://github.com/IbrahimElshishtawy/Employee_jops/releases/latest',
      releaseNotes: (map['releaseNotes'] as String?) ?? '',
      releaseNotesAr: map['releaseNotesAr'] as String?,
      releaseNotesEn: map['releaseNotesEn'] as String?,
      forceUpdate: map['forceUpdate'] as bool? ?? false,
      publishedAt: map['publishedAt'] != null
          ? DateTime.tryParse(map['publishedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latestVersion': latestVersion.fullVersion,
      'minimumSupportedVersion': minimumSupportedVersion.fullVersion,
      'androidStoreUrl': androidStoreUrl,
      'iosStoreUrl': iosStoreUrl,
      'releaseNotes': releaseNotes,
      'releaseNotesAr': releaseNotesAr,
      'releaseNotesEn': releaseNotesEn,
      'forceUpdate': forceUpdate,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }
}

@immutable
class UpdateCheckResult {
  final bool hasUpdate;
  final bool isForceUpdate;
  final UpdateType updateType;
  final AppVersion currentVersion;
  final AppVersion availableVersion;
  final UpdateConfig config;
  final int? shorebirdPatchNumber;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.hasUpdate,
    required this.isForceUpdate,
    required this.updateType,
    required this.currentVersion,
    required this.availableVersion,
    required this.config,
    this.shorebirdPatchNumber,
    this.errorMessage,
  });

  factory UpdateCheckResult.noUpdate({
    required AppVersion currentVersion,
    required UpdateConfig config,
    int? shorebirdPatchNumber,
  }) {
    return UpdateCheckResult(
      hasUpdate: false,
      isForceUpdate: false,
      updateType: UpdateType.none,
      currentVersion: currentVersion,
      availableVersion: currentVersion,
      config: config,
      shorebirdPatchNumber: shorebirdPatchNumber,
    );
  }

  factory UpdateCheckResult.storeUpdateAvailable({
    required AppVersion currentVersion,
    required AppVersion availableVersion,
    required UpdateConfig config,
    required bool isForceUpdate,
  }) {
    return UpdateCheckResult(
      hasUpdate: true,
      isForceUpdate: isForceUpdate,
      updateType: UpdateType.normalRelease,
      currentVersion: currentVersion,
      availableVersion: availableVersion,
      config: config,
    );
  }

  factory UpdateCheckResult.shorebirdPatchReady({
    required AppVersion currentVersion,
    required UpdateConfig config,
    required int patchNumber,
  }) {
    return UpdateCheckResult(
      hasUpdate: true,
      isForceUpdate: false,
      updateType: UpdateType.shorebirdPatch,
      currentVersion: currentVersion,
      availableVersion: currentVersion,
      config: config,
      shorebirdPatchNumber: patchNumber,
    );
  }
}
