import '../models/location_result.dart';

abstract class LocationService {
  Future<LocationResult> getCurrentLocation();
  Future<bool> isLocationServiceEnabled();
  Future<bool> requestPermission();
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  });
  bool isWithinAllowedRadius(double distanceMeters, [double allowedRadiusMeters = 4.0]);
}
