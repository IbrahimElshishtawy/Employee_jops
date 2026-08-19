import '../../../attendance/data/services/mock_biometric_service.dart';
import '../../../attendance/data/services/mock_location_service.dart';

class DemoControlsState {
  final bool useRealDeviceSensors;
  final MockLocationMode locationMode;
  final double simulatedDistance;
  final MockBiometricMode biometricMode;
  final bool isOnline;

  const DemoControlsState({
    this.useRealDeviceSensors = true,
    this.locationMode = MockLocationMode.insideRange,
    this.simulatedDistance = 2.3,
    this.biometricMode = MockBiometricMode.alwaysSuccess,
    this.isOnline = true,
  });

  DemoControlsState copyWith({
    bool? useRealDeviceSensors,
    MockLocationMode? locationMode,
    double? simulatedDistance,
    MockBiometricMode? biometricMode,
    bool? isOnline,
  }) {
    return DemoControlsState(
      useRealDeviceSensors: useRealDeviceSensors ?? this.useRealDeviceSensors,
      locationMode: locationMode ?? this.locationMode,
      simulatedDistance: simulatedDistance ?? this.simulatedDistance,
      biometricMode: biometricMode ?? this.biometricMode,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
