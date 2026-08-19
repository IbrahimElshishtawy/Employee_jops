import '../../domain/models/location_result.dart';
import '../../domain/services/mock_location_detector.dart';

/// Concrete implementation of MockLocationDetector.
/// Uses platform location provider checks and location object indicators.
class MockLocationDetectorImpl implements MockLocationDetector {
  bool simulatedMockDetected;

  MockLocationDetectorImpl({this.simulatedMockDetected = false});

  @override
  Future<bool> isMockLocation(LocationResult locationResult) async {
    if (simulatedMockDetected) return true;
    if (locationResult.isMockLocation) return true;
    if (locationResult.status == LocationStatus.mockLocationDetected) return true;
    return false;
  }

  @override
  Future<bool> hasMockLocationAppsOrFlags() async {
    return simulatedMockDetected;
  }
}
