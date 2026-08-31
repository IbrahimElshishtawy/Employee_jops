import 'package:flutter/foundation.dart';

@immutable
class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;
  final int buildNumber;

  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.buildNumber = 0,
  });

  /// Parses strings like "1.2.0", "1.2.0+12", "v1.2.0", "v1.2.0+12"
  factory AppVersion.parse(String versionString) {
    var clean = versionString.trim();
    if (clean.startsWith('v') || clean.startsWith('V')) {
      clean = clean.substring(1);
    }

    int build = 0;
    if (clean.contains('+')) {
      final parts = clean.split('+');
      clean = parts[0];
      if (parts.length > 1) {
        build = int.tryParse(parts[1]) ?? 0;
      }
    }

    final segments = clean.split('.');
    final major = segments.isNotEmpty ? (int.tryParse(segments[0]) ?? 0) : 0;
    final minor = segments.length > 1 ? (int.tryParse(segments[1]) ?? 0) : 0;
    final patch = segments.length > 2 ? (int.tryParse(segments[2]) ?? 0) : 0;

    return AppVersion(
      major: major,
      minor: minor,
      patch: patch,
      buildNumber: build,
    );
  }

  /// Base semantic string without build number e.g. "1.2.0"
  String get semanticVersion => '$major.$minor.$patch';

  /// Full version string including build number e.g. "1.2.0+12"
  String get fullVersion =>
      buildNumber > 0 ? '$semanticVersion+$buildNumber' : semanticVersion;

  /// User-friendly label
  String get userFacingVersion => semanticVersion;

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    if (buildNumber != other.buildNumber && buildNumber > 0 && other.buildNumber > 0) {
      return buildNumber.compareTo(other.buildNumber);
    }
    return 0;
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator <=(AppVersion other) => compareTo(other) <= 0;
  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator >=(AppVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppVersion &&
        other.major == major &&
        other.minor == minor &&
        other.patch == patch &&
        other.buildNumber == buildNumber;
  }

  @override
  int get hashCode =>
      major.hashCode ^ minor.hashCode ^ patch.hashCode ^ buildNumber.hashCode;

  @override
  String toString() => fullVersion;
}
