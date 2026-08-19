import 'dart:math' as math;

/// GeofenceService handles geodesic distance calculations and workplace boundary verification.
class GeofenceService {
  const GeofenceService();

  static const double earthRadiusMeters = 6371000.0;

  /// Calculates geodesic distance between two GPS points in meters using the Haversine formula.
  double calculateDistanceInMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final dLat = _degreesToRadians(endLatitude - startLatitude);
    final dLon = _degreesToRadians(endLongitude - startLongitude);

    final lat1 = _degreesToRadians(startLatitude);
    final lat2 = _degreesToRadians(endLatitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Verifies if a calculated distance is strictly within the allowed radius.
  bool isWithinRadius({
    required double distanceInMeters,
    required double allowedRadiusMeters,
  }) {
    return distanceInMeters >= 0 && distanceInMeters <= allowedRadiusMeters;
  }

  /// Verifies if GPS coordinates are inside the workplace geofence.
  bool isInsideGeofence({
    required double currentLatitude,
    required double currentLongitude,
    required double workplaceLatitude,
    required double workplaceLongitude,
    required double allowedRadiusMeters,
  }) {
    final distance = calculateDistanceInMeters(
      startLatitude: currentLatitude,
      startLongitude: currentLongitude,
      endLatitude: workplaceLatitude,
      endLongitude: workplaceLongitude,
    );
    return isWithinRadius(
      distanceInMeters: distance,
      allowedRadiusMeters: allowedRadiusMeters,
    );
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
