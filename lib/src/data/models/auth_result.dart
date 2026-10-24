/// Result type for functional error handling without untyped exceptions.
sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get dataOrNull =>
      this is Success<T, E> ? (this as Success<T, E>).data : null;

  E? get errorOrNull =>
      this is Failure<T, E> ? (this as Failure<T, E>).error : null;

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(E error) onFailure,
  }) {
    if (this is Success<T, E>) {
      return onSuccess((this as Success<T, E>).data);
    } else {
      return onFailure((this as Failure<T, E>).error);
    }
  }
}

class Success<T, E> extends Result<T, E> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);

  @override
  String toString() => 'Failure($error)';
}

/// Standardized error codes for Ustaad authentication.
enum AuthErrorCode {
  invalidEmail,
  userNotFound,
  wrongPassword,
  emailAlreadyInUse,
  weakPassword,
  invalidPhoneNumber,
  invalidVerificationCode,
  codeExpired,
  quotaExceeded,
  networkRequestFailed,
  userDisabled,
  unknown,
}

/// Strongly-typed authentication error object.
class AuthError {
  final AuthErrorCode code;
  final String message;
  final dynamic originalError;

  const AuthError({
    required this.code,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'AuthError(code: $code, message: $message)';
}
