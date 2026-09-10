import 'package:inventory_count_app/core/error/failures.dart';

/// Outcome of a domain-layer operation. Use cases and repositories return
/// this instead of throwing, so the presentation layer always has an
/// exhaustive, compiler-checked set of states to handle.
sealed class ApiResult<T> {
  const ApiResult();

  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      ResultSuccess<T>(:final data) => onSuccess(data),
      ResultFailure<T>(:final failure) => onFailure(failure),
    };
  }

  bool get isSuccess => this is ResultSuccess<T>;
}

final class ResultSuccess<T> extends ApiResult<T> {
  const ResultSuccess(this.data);
  final T data;
}

final class ResultFailure<T> extends ApiResult<T> {
  const ResultFailure(this.failure);
  final Failure failure;
}
