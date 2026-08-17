enum BiometricAuthResult {
  success,
  failed,
  cancelled,
  notAvailable,
}

abstract class BiometricService {
  Future<BiometricAuthResult> authenticate({String reason = 'يرجى تأكيد بصمتك لتسجيل الحضور'});
}
