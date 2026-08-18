import 'dart:math' as math;
import '../../../../core/constants/app_constants.dart';

/// Business policy for validating attendance geofence and GPS rules.
///
/// Business Rules:
/// - Maximum allowed distance from workplace = 4.0 meters.
/// - Distance <= 4.0 meters -> Inside allowed attendance zone.
/// - Distance > 4.0 meters -> Outside allowed attendance zone.
/// - Maximum acceptable GPS accuracy = 20.0 meters.
/// - Maximum acceptable location age (staleness) = 60 seconds.
class AttendanceLocationPolicy {
  AttendanceLocationPolicy._();

  /// Maximum allowed radius in meters for workplace attendance check-in/out.
  static const double maxAllowedRadiusMeters = AppConstants.maxAllowedDistanceMeters; // 4.0m

  /// Maximum acceptable GPS accuracy in meters.
  static const double maxAcceptableAccuracyMeters = 20.0;

  /// Maximum allowed age of GPS fix before being considered stale.
  static const Duration maxLocationAge = Duration(seconds: 60);

  /// Calculates geodesic distance between two GPS coordinates using Haversine formula.
  /// Returns distance in meters.
  static double calculateDistanceInMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    const double earthRadiusMeters = 6371000.0;

    final dLat = _degreesToRadians(endLatitude - startLatitude);
    final dLon = _degreesToRadians(endLongitude - startLongitude);

    final lat1 = _degreesToRadians(startLatitude);
    final lat2 = _degreesToRadians(endLatitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Verifies if a given distance is strictly within the allowed workplace radius.
  static bool isWithinAllowedRadius(double distanceInMeters, [double allowedRadius = maxAllowedRadiusMeters]) {
    return distanceInMeters >= 0 && distanceInMeters <= allowedRadius;
  }

  /// Verifies if the GPS accuracy is acceptable for attendance.
  static bool isAccuracyAcceptable(double accuracyMeters) {
    return accuracyMeters > 0 && accuracyMeters <= maxAcceptableAccuracyMeters;
  }

  /// Verifies if a location timestamp is fresh enough.
  static bool isLocationStale(DateTime timestamp, [DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    return now.difference(timestamp).abs() > maxLocationAge;
  }

  /// Validates whether the employee's current GPS coordinates are within the workplace radius.
  static bool isLocationValidForAttendance({
    required double currentLatitude,
    required double currentLongitude,
    required double workplaceLatitude,
    required double workplaceLongitude,
    double allowedRadius = maxAllowedRadiusMeters,
  }) {
    final distance = calculateDistanceInMeters(
      startLatitude: currentLatitude,
      startLongitude: currentLongitude,
      endLatitude: workplaceLatitude,
      endLongitude: workplaceLongitude,
    );
    return isWithinAllowedRadius(distance, allowedRadius);
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
