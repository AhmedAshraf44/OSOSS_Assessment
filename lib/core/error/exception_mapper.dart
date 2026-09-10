import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/core/error/failures.dart';
import 'package:inventory_count_app/core/result/api_result.dart';

/// Runs [action] and maps any known data-layer exception to a [Failure].
///
/// Every repository's methods are one-liners around this instead of
/// repeating the same try/catch block, so all repositories map errors the
/// same way (CLAUDE.md: catch at the data-layer boundary, shared logic in
/// core/).
Future<ApiResult<T>> guardApiCall<T>(Future<T> Function() action) async {
  try {
    return ResultSuccess(await action());
  } on NetworkException catch (e) {
    return ResultFailure(NetworkFailure(e.message));
  } on RequestTimeoutException catch (e) {
    return ResultFailure(TimeoutFailure(e.message));
  } on UnauthorizedException catch (e) {
    return ResultFailure(UnauthorizedFailure(e.message));
  } on ServerException catch (e) {
    return ResultFailure(ServerFailure(e.statusCode, e.message));
  } on MalformedResponseException catch (e) {
    return ResultFailure(ParsingFailure(e.message));
  } on LocalStorageException catch (e) {
    return ResultFailure(StorageFailure(e.message));
  } catch (_) {
    return const ResultFailure(UnknownFailure());
  }
}
