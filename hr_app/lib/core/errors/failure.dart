/// Clean Domain-level Failure representations
sealed class Failure {
  final String message;
  final int? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Unable to connect to server. Please check your connection.'})
      : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure({String message = 'Authentication failed. Please verify credentials.'})
      : super(message, code: 401);
}

class PermissionFailure extends Failure {
  const PermissionFailure({String message = 'You do not have permission to perform this action.'})
      : super(message, code: 403);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({String message = 'The requested item could not be found.'})
      : super(message, code: 404);
}

class ValidationFailure extends Failure {
  const ValidationFailure({String message = 'Please correct the invalid fields and try again.'})
      : super(message, code: 422);
}

class ServerFailure extends Failure {
  const ServerFailure({String message = 'A server error occurred. Please try again later.'})
      : super(message, code: 500);
}

class UnknownFailure extends Failure {
  const UnknownFailure({String message = 'An unexpected error occurred. Please try again.'})
      : super(message);
}
