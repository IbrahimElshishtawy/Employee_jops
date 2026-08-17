enum LocationStatus {
  insideRange,
  outsideRange,
  permissionDenied,
  gpsDisabled,
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

  bool get isInsideRange => status == LocationStatus.insideRange && distanceFromOfficeMeters <= 4.0;
}
