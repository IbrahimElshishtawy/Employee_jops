import '../entities/employee_location.dart';
import '../entities/tracking_enums.dart';
import '../repositories/location_tracking_repository.dart';

class StartLocationTrackingUseCase {
  final LocationTrackingRepository _repository;

  StartLocationTrackingUseCase(this._repository);

  Future<bool> call({
    required String workSessionId,
    required String employeeId,
    int intervalSeconds = 30,
    int distanceFilterMeters = 10,
  }) {
    return _repository.startTracking(
      workSessionId: workSessionId,
      employeeId: employeeId,
      intervalSeconds: intervalSeconds,
      distanceFilterMeters: distanceFilterMeters,
    );
  }
}

class StopLocationTrackingUseCase {
  final LocationTrackingRepository _repository;

  StopLocationTrackingUseCase(this._repository);

  Future<void> call({String? reason}) {
    return _repository.stopTracking(reason: reason);
  }
}

class GetCurrentLocationUseCase {
  final LocationTrackingRepository _repository;

  GetCurrentLocationUseCase(this._repository);

  Future<EmployeeLocation?> call() {
    return _repository.getCurrentLocation();
  }
}

class GetTrackingStatusUseCase {
  final LocationTrackingRepository _repository;

  GetTrackingStatusUseCase(this._repository);

  TrackingStatus call() {
    return _repository.trackingStatus;
  }
}

class SyncLocationUseCase {
  final LocationTrackingRepository _repository;

  SyncLocationUseCase(this._repository);

  Future<int> call() {
    return _repository.syncOfflineLocations();
  }
}
