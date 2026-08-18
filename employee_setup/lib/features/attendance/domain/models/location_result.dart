import '../services/attendance_location_policy.dart';

enum LocationStatus {
  insideRange,
  outsideRange,
  permissionDenied,
  permissionDeniedForever,
  gpsDisabled,
  locationUnavailable,
  error,
}

class LocationResult {
  final double latitude;
  final double longitude;
  final double distanceFromOfficeMeters;
  final LocationStatus status;
  final String? errorMessage;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.distanceFromOfficeMeters,
    required this.status,
    this.errorMessage,
  });

  /// Validates that status is insideRange and distance is strictly <= 4 meters.
  bool get isInsideRange =>
      status == LocationStatus.insideRange &&
      AttendanceLocationPolicy.isWithinAllowedRadius(distanceFromOfficeMeters);

  bool get isPermissionDenied =>
      status == LocationStatus.permissionDenied ||
      status == LocationStatus.permissionDeniedForever;

  bool get isGpsDisabled => status == LocationStatus.gpsDisabled;

  LocationResult copyWith({
    double? latitude,
    double? longitude,
    double? distanceFromOfficeMeters,
    LocationStatus? status,
    String? errorMessage,
  }) {
    return LocationResult(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceFromOfficeMeters:
          distanceFromOfficeMeters ?? this.distanceFromOfficeMeters,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
