import 'package:wave/core/error/failures.dart';

/// A tiny Either. Repositories return `Result<T>`; BLoCs fold it.
/// (dartz is in pubspec for the places that want the full API, but a sealed
/// class keeps the common path readable and exhaustively switchable.)
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;

  R fold<R>(R Function(Failure f) onFailure, R Function(T value) onSuccess) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Err<T>(:final failure) => onFailure(failure),
    };
  }

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Err<T>() => null,
      };
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
