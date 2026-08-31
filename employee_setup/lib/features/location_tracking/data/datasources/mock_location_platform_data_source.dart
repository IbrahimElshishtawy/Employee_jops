import 'dart:async';
import '../../domain/entities/employee_location.dart';
import '../../domain/entities/tracking_enums.dart';
import 'location_platform_data_source.dart';

/// Mock platform data source for testing and demo mode without hardware sensors
class MockLocationPlatformDataSource implements LocationPlatformDataSource {
  LocationPermissionState permissionState = LocationPermissionState.foregroundGranted;
  bool isServiceEnabled = true;
  double simulatedLatitude;
  double simulatedLongitude;
  double simulatedAccuracy;

  final StreamController<EmployeeLocation> _streamController =
      StreamController<EmployeeLocation>.broadcast();

  MockLocationPlatformDataSource({
    this.simulatedLatitude = 30.0444,
    this.simulatedLongitude = 31.2357,
    this.simulatedAccuracy = 3.5,
  });

  @override
  Future<bool> isLocationServiceEnabled() async => isServiceEnabled;

  @override
  Future<LocationPermissionState> checkPermission() async => permissionState;

  @override
  Future<LocationPermissionState> requestPermission({bool requestBackground = true}) async {
    return permissionState;
  }

  @override
  Future<EmployeeLocation?> getCurrentPosition() async {
    if (!isServiceEnabled || permissionState.isDenied) return null;
    return EmployeeLocation(
      latitude: simulatedLatitude,
      longitude: simulatedLongitude,
      accuracy: simulatedAccuracy,
      timestamp: DateTime.now(),
      source: LocationSource.gps,
    );
  }

  @override
  Stream<EmployeeLocation> getPositionStream({
    int intervalSeconds = 30,
    int distanceFilterMeters = 10,
  }) {
    return _streamController.stream;
  }

  void emitLocation(EmployeeLocation location) {
    if (!_streamController.isClosed) {
      _streamController.add(location);
    }
  }

  void dispose() {
    _streamController.close();
  }
}
