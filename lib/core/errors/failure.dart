abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => '$runtimeType: $message';
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'A cache error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class AuthFailure extends Failure {
  /// Firebase/app error code (e.g. 'invalid-credential', 'needs-role'), used by
  /// the UI to show a localized message. Null for older call sites.
  final String? code;
  const AuthFailure(super.message, [this.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
