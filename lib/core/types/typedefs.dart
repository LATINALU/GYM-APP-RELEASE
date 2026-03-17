import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Result type for operations that can fail
typedef Result<T> = Either<Failure, T>;

/// Async result type
typedef FutureResult<T> = Future<Result<T>>;

/// Void result for operations without return value
typedef FutureVoidResult = Future<Result<void>>;

/// Extension methods for Result type
extension ResultX<T> on Result<T> {
  /// Returns true if this is a success
  bool get isSuccess => isRight();

  /// Returns true if this is a failure
  bool get isFailure => isLeft();

  /// Gets the value or throws if failure
  T getOrThrow() => fold(
        (failure) => throw Exception(failure.message),
        (value) => value,
      );

  /// Gets the value or returns a default
  T getOrElse(T defaultValue) => fold(
        (_) => defaultValue,
        (value) => value,
      );

  /// Gets the failure if present
  Failure? get failure => fold(
        (f) => f,
        (_) => null,
      );

  /// Gets the value if present
  T? get value => fold(
        (_) => null,
        (v) => v,
      );
}
