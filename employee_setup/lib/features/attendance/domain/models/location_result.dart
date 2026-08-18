import '../services/attendance_location_policy.dart';

enum LocationStatus {
  insideRange,
  outsideRange,
  permissionDenied,
  permissionDeniedForever,
  gpsDisabled,
  locationUnavailable,
  lowAccuracy,
  staleLocation,
  mockLocationDetected,
  error,
}

class LocationResult {
  final double latitude;
  final double longitude;
  final double distanceFromOfficeMeters;
  final double accuracyMeters;
  final DateTime timestamp;
  final bool isMockLocation;
  final LocationStatus status;
  final String? errorMessage;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.distanceFromOfficeMeters,
    this.accuracyMeters = 3.0,
    required this.timestamp,
    this.isMockLocation = false,
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

  bool get isAccuracyValid =>
      AttendanceLocationPolicy.isAccuracyAcceptable(accuracyMeters);

  bool get isStale =>
      AttendanceLocationPolicy.isLocationStale(timestamp);

  LocationResult copyWith({
    double? latitude,
    double? longitude,
    double? distanceFromOfficeMeters,
    double? accuracyMeters,
    DateTime? timestamp,
    bool? isMockLocation,
    LocationStatus? status,
    String? errorMessage,
  }) {
    return LocationResult(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceFromOfficeMeters:
          distanceFromOfficeMeters ?? this.distanceFromOfficeMeters,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      timestamp: timestamp ?? this.timestamp,
      isMockLocation: isMockLocation ?? this.isMockLocation,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
