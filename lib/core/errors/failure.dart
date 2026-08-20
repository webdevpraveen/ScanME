/// Functional failure type for Result pattern
sealed class Failure {
  const Failure(this.message, [this.exception]);

  final String message;
  final Object? exception;

  @override
  String toString() => '$runtimeType: $message';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.exception]);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.exception]);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.exception]);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.exception]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.exception]);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message, [super.exception]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Something went wrong', Object? exception])
      : super(message, exception);
}
