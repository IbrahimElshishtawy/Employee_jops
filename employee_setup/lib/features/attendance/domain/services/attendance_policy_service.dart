import '../models/location_result.dart';

/// AttendancePolicyService centralizes enterprise attendance validation rules and thresholds.
class AttendancePolicyService {
  /// Default allowed radius if not specified in employee profile.
  static const double defaultAllowedRadiusMeters = 4.0;

  /// Maximum acceptable GPS accuracy in meters. (Accuracy > 20m is unacceptable)
  static const double maxAcceptableAccuracyMeters = 20.0;

  /// Maximum acceptable age of GPS fix before being deemed stale.
  static const Duration maxLocationAge = Duration(seconds: 60);

  /// Maximum allowed timestamp drift between client and server (5 minutes).
  static const Duration maxAllowedTimeDrift = Duration(minutes: 5);

  const AttendancePolicyService();

  /// Validates whether the given GPS accuracy is acceptable for security compliance.
  bool isAccuracyAcceptable(double accuracyMeters) {
    return accuracyMeters > 0 && accuracyMeters <= maxAcceptableAccuracyMeters;
  }

  /// Validates whether a location fix timestamp is fresh.
  bool isLocationFresh(DateTime locationTimestamp, [DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    return now.difference(locationTimestamp).abs() <= maxLocationAge;
  }

  /// Evaluates the complete location verification policy.
  bool isLocationPolicySatisfied({
    required LocationResult locationResult,
    required double allowedRadiusMeters,
  }) {
    if (locationResult.isMockLocation) return false;
    if (locationResult.status == LocationStatus.mockLocationDetected) return false;
    if (!isAccuracyAcceptable(locationResult.accuracyMeters)) return false;
    if (!isLocationFresh(locationResult.timestamp)) return false;
    if (locationResult.distanceFromOfficeMeters > allowedRadiusMeters) return false;
    return true;
  }
}
