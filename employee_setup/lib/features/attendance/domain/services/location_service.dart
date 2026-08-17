import '../models/location_result.dart';

abstract class LocationService {
  Future<LocationResult> getCurrentLocation();
}
