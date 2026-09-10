// Exceptions thrown by data sources (local or remote). Repositories catch
// these at the data-layer boundary and map them to [Failure]s — domain and
// presentation layers never see a raw exception.

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection.']);
  final String message;
}

class RequestTimeoutException implements Exception {
  const RequestTimeoutException([this.message = 'The request timed out.']);
  final String message;
}

class UnauthorizedException implements Exception {
  const UnauthorizedException([
    this.message = 'Session expired or unauthorized.',
  ]);
  final String message;
}

/// Non-2xx response that isn't modeled as a more specific exception.
class ServerException implements Exception {
  const ServerException(this.statusCode, [this.message = 'Server error.']);
  final int statusCode;
  final String message;
}

class MalformedResponseException implements Exception {
  const MalformedResponseException([
    this.message = 'Invalid or malformed response.',
  ]);
  final String message;
}

class LocalStorageException implements Exception {
  const LocalStorageException([
    this.message = 'Local storage operation failed.',
  ]);
  final String message;
}
