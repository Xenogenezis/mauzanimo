/// Typed result class for error handling
/// Replaces throwing exceptions with explicit success/failure states
abstract class Result<T> {
  const Result();
  factory Result.success(T data) = Success<T>;
  factory Result.failure(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) = Failure<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success(data: $data)';
}

class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.error, this.stackTrace});

  @override
  String toString() => 'Failure(message: $message, error: $error)';
}

/// Extension for convenient Result handling
extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull {
    if (this is Success<T>) return (this as Success<T>).data;
    return null;
  }

  String? get errorOrNull {
    if (this is Failure<T>) return (this as Failure<T>).message;
    return null;
  }

  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else if (this is Failure<T>) {
      return failure((this as Failure<T>).message);
    }
    throw StateError('Unknown Result type');
  }
}
