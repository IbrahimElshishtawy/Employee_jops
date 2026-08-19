import '../models/location_result.dart';

/// MockLocationDetector checks for platform mock location signals,
/// mock provider indicators, and anomalous location characteristics.
abstract class MockLocationDetector {
  /// Evaluates whether a given [LocationResult] or device state is a mock/fake location.
  Future<bool> isMockLocation(LocationResult locationResult);

  /// Performs platform-specific checks for mock location providers.
  Future<bool> hasMockLocationAppsOrFlags();
}
