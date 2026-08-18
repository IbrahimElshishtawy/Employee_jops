import '../../domain/services/biometric_service.dart';

enum MockBiometricMode {
  alwaysSuccess,
  alwaysFail,
  alwaysCancel,
  notAvailable,
}

class MockBiometricService implements BiometricService {
  MockBiometricMode mode;

  MockBiometricService({
    this.mode = MockBiometricMode.alwaysSuccess,
  });

  @override
  Future<BiometricAuthResult> authenticate({
    String reason = 'يرجى تأكيد بصمتك لتسجيل الحضور',
  }) async {
    // Artificial small delay for biometric prompt dialog
    await Future.delayed(const Duration(milliseconds: 400));

    switch (mode) {
      case MockBiometricMode.alwaysSuccess:
        return BiometricAuthResult.success;
      case MockBiometricMode.alwaysFail:
        return BiometricAuthResult.failed;
      case MockBiometricMode.alwaysCancel:
        return BiometricAuthResult.cancelled;
      case MockBiometricMode.notAvailable:
        return BiometricAuthResult.notAvailable;
    }
  }

  @override
  Future<bool> canCheckBiometrics() async {
    return mode != MockBiometricMode.notAvailable;
  }

  @override
  Future<bool> isDeviceSupported() async {
    return mode != MockBiometricMode.notAvailable;
  }
}
