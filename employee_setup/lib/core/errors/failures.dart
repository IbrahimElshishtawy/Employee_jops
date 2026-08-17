/// Base class for all domain failure results.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الاتصال بالخادم', super.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'لا يوجد اتصال بالإنترنت', super.code]);
}

class LocationFailure extends Failure {
  const LocationFailure([super.message = 'فشل تحديد الموقع الجغرافي', super.code]);
}

class BiometricFailure extends Failure {
  const BiometricFailure([super.message = 'فشلت المصادقة البيومترية', super.code]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'خطأ في قراءة البيانات المحلية', super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'البيانات المدخلة غير صحيحة', super.code]);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'فشل تسجيل الدخول', super.code]);
}
