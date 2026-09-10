import 'package:equatable/equatable.dart';

/// Typed, presentation-friendly error outcomes. Every data-layer exception
/// is mapped to exactly one of these at the repository boundary, so nothing
/// above the data layer ever catches a raw [Exception].
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'The request timed out.']);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Session expired. Please sign in again.',
  ]);
}

final class ServerFailure extends Failure {
  const ServerFailure(
    this.statusCode, [
    super.message = 'Something went wrong on the server.',
  ]);

  final int statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

final class ParsingFailure extends Failure {
  const ParsingFailure([
    super.message = 'Received an unexpected response format.',
  ]);
}

final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Could not read or write local data.']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
